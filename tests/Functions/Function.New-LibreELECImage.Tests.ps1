Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "New-LibreELECImage" {

        Context "create LibreELEC image" {

            It "Can create 4gb SD image" {
                $customSettings = @{
                    arm_freq = 1350
                    core_freq = 500
                    over_voltage = 4
                    gpu_mem = 320
                    # force_turbo = 1 # Voids Warranty! (uncomment to avoid CPU scaling down to 600Mhz)
                    # boot_delay = 1 # Helps to avoid sdcard corruption when force_turbo is enabled.
                    # sdram_freq = 500 # Uncomment to test (works only with some boards).
                }

                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                New-LibreELECImage -SDDeviceFilePath "/$TestDrive/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -FilePath $file.FullName -CustomSettings $customSettings

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $devicePath = [Losetup]::Lookup()

                $device = [DeviceService]::GetDevice($devicePath)

                [Losetup]::Attach($device.GetPath(), "/$TestDrive/LibreELEC-SD-Image.img")

                [Partprobe]::Probe($device)

                $device = [DeviceService]::GetDevice($devicePath)

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                ($device.GetPartition(1)).Label | Should Be "STORAGE"
                ($device.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/SYSTEM" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/config.txt" -PathType Leaf | Should Be $true

                "$source/cmdline.txt" | Should Contain "^boot=LABEL=SYSTEM disk=LABEL=STORAGE quiet$"
                "$source/config.txt" | Should Contain "^ over_voltage=4$"
                "$source/config.txt" | Should Contain "^ arm_freq=1350$"
                "$source/config.txt" | Should Contain "^ core_freq=500$"

                $device = [DeviceService]::GetDevice($devicePath)
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                [Losetup]::Detach($device.GetPath())

                Remove-Item -Path $source -Recurse -Force
            }

            It "Can create 8gb USB image" {
                $customSettings = @{
                    arm_freq = 1350
                    core_freq = 500
                    over_voltage = 4
                    gpu_mem = 320
                    # force_turbo = 1 # Voids Warranty! (uncomment to avoid CPU scaling down to 600Mhz)
                    # boot_delay = 1 # Helps to avoid sdcard corruption when force_turbo is enabled.
                    # sdram_freq = 500 # Uncomment to test (works only with some boards).
                }

                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                New-LibreELECImage -SDDeviceFilePath "/$TestDrive/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -USBDeviceFilePath "/$TestDrive/LibreELEC-USB-Image.img" -USBDeviceSize 8gb -FilePath $file.FullName -CustomSettings $customSettings

                $devicePath = [Losetup]::Lookup()

                $device = [DeviceService]::GetDevice($devicePath)

                [Losetup]::Attach($device.GetPath(), "/$TestDrive/LibreELEC-SD-Image.img")

                [Partprobe]::Probe($device)

                $device = [DeviceService]::GetDevice($devicePath)

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                $device.GetPartition(1) | Should Be $null

                [Losetup]::Detach($device.GetPath())

                $devicePath = [Losetup]::Lookup()

                $device = [DeviceService]::GetDevice($devicePath)

                [Losetup]::Attach($device.GetPath(), "/$TestDrive/LibreELEC-USB-Image.img")

                [Partprobe]::Probe($device)

                $device = [DeviceService]::GetDevice($devicePath)

                ($device.GetPartition(0)).Label | Should Be "STORAGE"
                ($device.GetPartition(0)).FSType | Should Be "ext4"
                $device.GetPartition(1) | Should Be $null

                [Losetup]::Detach($device.GetPath())
            }
        }

        Context "restoring LibreELEC image" {
            It "Can restore to 4gb SD image" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                $backup = Get-ChildItem -Path '/home/ubuntu/Backups/' -Filter "LibreELEC-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                New-LibreELECImage -SDDeviceFilePath "/$TestDrive/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -FilePath $file.FullName -RestoreFilePath $backup.FullName

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $devicePath = [Losetup]::Lookup()

                $device = [DeviceService]::GetDevice($devicePath)

                [Losetup]::Attach($device.GetPath(), "/$TestDrive/LibreELEC-SD-Image.img")

                [Partprobe]::Probe($device)

                $device = [DeviceService]::GetDevice($devicePath)

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                ($device.GetPartition(1)).Label | Should Be "STORAGE"
                ($device.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($device.GetPartition(1), $source)

                Test-Path -Path "$source/.kodi/addons" -PathType Container | Should Be $true
                Test-Path -Path "$source/.kodi/userdata" -PathType Container | Should Be $true

                $device = [DeviceService]::GetDevice($devicePath)
                if ($device.GetPartition(1).Umount()) {
                    [Utility]::Umount($device.GetPartition(1))
                }

                [Losetup]::Detach($device.GetPath())

                Remove-Item -Path $source -Recurse -Force
            }
        }
    }
}
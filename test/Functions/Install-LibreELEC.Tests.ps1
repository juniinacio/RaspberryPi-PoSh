Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Install-LibreELEC" -Tags "CI" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/tmp' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $SDDevicePath = '/dev/loop0'

            $USBDeviceFilePath = Join-Path -Path '/tmp' -ChildPath "USB-8gb.img"
            if (-not (Test-Path -Path $USBDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }
            
            $USBDevicePath = '/dev/loop1'

            $FilePath = Get-ChildItem -Path '/downloads' -Filter "LibreELEC-RPi2.arm-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

            $RestoreFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'assets/RestoreFileELEC.tar'

            $CustomSettings = @{
                max_usb_current = 1
                gpu_mem = 320
                gpu_mem_1024 = 320
            }
        }

        It "Should be able to install SD" -Skip:$Skip {
            Install-LibreELEC -SDDevicePath $SDDevicePath -SDDeviceFilePath $SDDeviceFilePath -FilePath $FilePath -CustomSettings $CustomSettings

            $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

            $null = New-Item -Path $mountpoint -ItemType Directory

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Losetup]::Attach($SD, $SDDeviceFilePath)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
            ($SD.GetPartition(0)).FSType | Should Be "vfat"
            ($SD.GetPartition(1)).Label | Should Be "STORAGE"
            ($SD.GetPartition(1)).FSType | Should Be "ext4"

            [Utility]::Mount($SD.GetPartition(0), $mountpoint)

            Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
            Test-Path -Path "$mountpoint/SYSTEM" -PathType Leaf | Should Be $true
            Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
            Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
            Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true

            "$mountpoint/cmdline.txt" | Should Contain "^boot=LABEL=SYSTEM disk=LABEL=STORAGE quiet$"

            "$mountpoint/config.txt" | Should Contain "^  force_turbo=0$"
            "$mountpoint/config.txt" | Should Contain "^  max_usb_current=1$"
            "$mountpoint/config.txt" | Should Contain "^  gpu_mem=320$"
            "$mountpoint/config.txt" | Should Contain "^  gpu_mem_1024=320$"

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            [Losetup]::Detach($SD)
        }

        It "Should be able to install USB" -Skip:$Skip {
            Install-LibreELEC -SDDevicePath $SDDevicePath -SDDeviceFilePath $SDDeviceFilePath -USBDevicePath $USBDevicePath -USBDeviceFilePath $USBDeviceFilePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

            $mountpoint = Join-Path -Path $TestDrive -ChildPath "Storage"

            $null = New-Item -Path $mountpoint -ItemType Directory

            $USB = [DeviceService]::GetDevice($USBDevicePath)

            [Losetup]::Attach($USB, $USBDeviceFilePath)

            $USB = [DeviceService]::GetDevice($USBDevicePath)

            ($USB.GetPartition(0)).Label | Should Be "STORAGE"
            ($USB.GetPartition(0)).FSType | Should Be "ext4"

            $USB.GetPartition(1) | Should Be $null

            [Utility]::Mount($USB.GetPartition(0), $mountpoint)

            Test-Path -Path "$mountpoint/.kodi/addons" -PathType Container | Should Be $true
            Test-Path -Path "$mountpoint/.kodi/userdata/guisettings.xml" -PathType Leaf | Should Be $true

            $USB = [DeviceService]::GetDevice($USBDevicePath)
            if ($USB.GetPartition(0).Umount()) {
                [Utility]::Umount($USB.GetPartition(0))
            }

            [Losetup]::Detach($USB)
        }

        AfterAll {
            
        }
    }
}
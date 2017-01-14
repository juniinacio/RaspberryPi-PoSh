Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Install-OSMC" {

        Context "installing OSMC" {

            It "Can install SD" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath $file.FullName

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                ($device.GetPartition(1)).Label | Should Be "STORAGE"
                ($device.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/config.txt" -PathType Leaf | Should Be $true

                "$source/cmdline.txt" | Should Contain "^root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet osmcdev=rbp2$"
                
                "$source/config.txt" | Should Contain "^ gpu_mem_1024=256$"
                "$source/config.txt" | Should Contain "^ hdmi_ignore_cec_init=1$"
                "$source/config.txt" | Should Contain "^ disable_overscan=1$"
                "$source/config.txt" | Should Contain "^ start_x=1$"
                "$source/config.txt" | Should Contain "^ disable_splash=1$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                [Utility]::Mount($device.GetPartition(1), $source)

                Test-Path -Path "$source/bin" -PathType Container | Should Be $true
                Test-Path -Path "$source/boot" -PathType Container | Should Be $true
                Test-Path -Path "$source/dev" -PathType Container | Should Be $true
                Test-Path -Path "$source/etc" -PathType Container | Should Be $true
                Test-Path -Path "$source/home" -PathType Container | Should Be $true
                Test-Path -Path "$source/lib" -PathType Container | Should Be $true
                Test-Path -Path "$source/lib64" -PathType Container | Should Be $true
                Test-Path -Path "$source/media" -PathType Container | Should Be $true
                Test-Path -Path "$source/mnt" -PathType Container | Should Be $true
                Test-Path -Path "$source/opt" -PathType Container | Should Be $true
                Test-Path -Path "$source/proc" -PathType Container | Should Be $true
                Test-Path -Path "$source/root" -PathType Container | Should Be $true
                Test-Path -Path "$source/run" -PathType Container | Should Be $true
                Test-Path -Path "$source/sbin" -PathType Container | Should Be $true
                Test-Path -Path "$source/selinux" -PathType Container | Should Be $true
                Test-Path -Path "$source/srv" -PathType Container | Should Be $true
                Test-Path -Path "$source/sys" -PathType Container | Should Be $true
                Test-Path -Path "$source/tmp" -PathType Container | Should Be $true
                Test-Path -Path "$source/usr" -PathType Container | Should Be $true
                Test-Path -Path "$source/var" -PathType Container | Should Be $true

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(1).Umount()) {
                    [Utility]::Umount($device.GetPartition(1))
                }

                Remove-Item -Path $source -Recurse -Force
            }

            It "Can install USB" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath $file.FullName

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                
                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                $device.GetPartition(1) | Should Be $null

                [Utility]::Mount($device.GetPartition(0), $source)

                "$source/cmdline.txt" | Should Contain "^root=/dev/sda1 rootfstype=ext4 rootwait quiet osmcdev=rbp2$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force

                $device = [DeviceService]::GetDevice('/dev/sdc')
                
                ($device.GetPartition(0)).Label | Should Be "STORAGE"
                ($device.GetPartition(0)).FSType | Should Be "ext4"
                $device.GetPartition(1) | Should Be $null

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/sdc')

                [Utility]::Mount($device.GetPartition(0), $source)

                # Test-Path -Path "$source/walkthrough_completed" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bin" -PathType Container | Should Be $true
                Test-Path -Path "$source/boot" -PathType Container | Should Be $true
                Test-Path -Path "$source/dev" -PathType Container | Should Be $true
                Test-Path -Path "$source/etc" -PathType Container | Should Be $true
                Test-Path -Path "$source/home" -PathType Container | Should Be $true
                Test-Path -Path "$source/lib" -PathType Container | Should Be $true
                Test-Path -Path "$source/lib64" -PathType Container | Should Be $true
                Test-Path -Path "$source/media" -PathType Container | Should Be $true
                Test-Path -Path "$source/mnt" -PathType Container | Should Be $true
                Test-Path -Path "$source/opt" -PathType Container | Should Be $true
                Test-Path -Path "$source/proc" -PathType Container | Should Be $true
                Test-Path -Path "$source/root" -PathType Container | Should Be $true
                Test-Path -Path "$source/run" -PathType Container | Should Be $true
                Test-Path -Path "$source/sbin" -PathType Container | Should Be $true
                Test-Path -Path "$source/selinux" -PathType Container | Should Be $true
                Test-Path -Path "$source/srv" -PathType Container | Should Be $true
                Test-Path -Path "$source/sys" -PathType Container | Should Be $true
                Test-Path -Path "$source/tmp" -PathType Container | Should Be $true
                Test-Path -Path "$source/usr" -PathType Container | Should Be $true
                Test-Path -Path "$source/var" -PathType Container | Should Be $true

                $device = [DeviceService]::GetDevice('/dev/sdc')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force
            }
        }

        Context "restoring OSMC" {
            It "Can restores SD" {

                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                $backup = Get-ChildItem -Path '/home/ubuntu/Backups/' -Filter "OSMC-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath $file.FullName -BackupFilePath $backup.FullName

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                ($device.GetPartition(1)).Label | Should Be "STORAGE"
                ($device.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/config.txt" -PathType Leaf | Should Be $true

                "$source/cmdline.txt" | Should Contain "^root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet osmcdev=rbp2$"
                
                "$source/config.txt" | Should Contain "^ gpu_mem_1024=256$"
                "$source/config.txt" | Should Contain "^ hdmi_ignore_cec_init=1$"
                "$source/config.txt" | Should Contain "^ disable_overscan=1$"
                "$source/config.txt" | Should Contain "^ start_x=1$"
                "$source/config.txt" | Should Contain "^ disable_splash=1$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                [Utility]::Mount($device.GetPartition(1), $source)

                Test-Path -Path "$source/walkthrough_completed" -PathType Leaf | Should Be $true

                Test-Path -Path "$source/home/osmc/.kodi/addons" -PathType Container | Should Be $true
                Test-Path -Path "$source/home/osmc/.kodi/userdata" -PathType Container | Should Be $true

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(1).Umount()) {
                    [Utility]::Umount($device.GetPartition(1))
                }

                Remove-Item -Path $source -Recurse -Force
            }

            It "Can restore USB" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                $backup = Get-ChildItem -Path '/home/ubuntu/Backups/' -Filter "OSMC-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath $file.FullName -BackupFilePath $backup.FullName

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                
                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                $device.GetPartition(1) | Should Be $null

                [Utility]::Mount($device.GetPartition(0), $source)

                "$source/cmdline.txt" | Should Contain "^root=/dev/sda1 rootfstype=ext4 rootwait quiet osmcdev=rbp2$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force

                $device = [DeviceService]::GetDevice('/dev/sdc')
                
                ($device.GetPartition(0)).Label | Should Be "STORAGE"
                ($device.GetPartition(0)).FSType | Should Be "ext4"
                $device.GetPartition(1) | Should Be $null

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/sdc')

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/walkthrough_completed" -PathType Leaf | Should Be $true

                Test-Path -Path "$source/home/osmc/.kodi/addons" -PathType Container | Should Be $true
                Test-Path -Path "$source/home/osmc/.kodi/userdata" -PathType Container | Should Be $true

                $device = [DeviceService]::GetDevice('/dev/sdc')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force
            }
        }
    }
}
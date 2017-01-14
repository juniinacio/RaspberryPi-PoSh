Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Install-OSMCInstaller" {

        Context "installing OSMC" {

            It "Can install SD" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMCInstaller -SD '/dev/mmcblk0' -FilePath $file.FullName

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                $device.GetPartition(1) | Should Be $null

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$source/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp2$"
                
                "$source/config.txt" | Should Contain "^disable_overscan=1$"
                "$source/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$source/config.txt" | Should Contain "^gpu_mem=16$"

                "$source/preseed.cfg" | Should Contain "^d-i target/storage string sd$"
                "$source/preseed.cfg" | Should Contain "^d-i network/interface string eth$"
                "$source/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force
            }

            It "Can install USB" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMCInstaller -SD '/dev/mmcblk0' -USB -FilePath $file.FullName

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                $device.GetPartition(1) | Should Be $null

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$source/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp2$"
                
                "$source/config.txt" | Should Contain "^disable_overscan=1$"
                "$source/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$source/config.txt" | Should Contain "^gpu_mem=16$"

                "$source/preseed.cfg" | Should Contain "^d-i target/storage string usb$"
                "$source/preseed.cfg" | Should Contain "^d-i network/interface string eth$"
                "$source/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force
            }

            It "Can install SD and enable WiFi" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "OSMC_TGT_rbp2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                Install-OSMCInstaller -SD '/dev/mmcblk0' -FilePath $file.FullName -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'Network 1'

                $source = "$TestDrive/SYSTEM"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                ($device.GetPartition(0)).Label | Should Be "SYSTEM"
                ($device.GetPartition(0)).FSType | Should Be "vfat"
                $device.GetPartition(1) | Should Be $null

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$source/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$source/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp2$"
                
                "$source/config.txt" | Should Contain "^disable_overscan=1$"
                "$source/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$source/config.txt" | Should Contain "^gpu_mem=16$"

                "$source/preseed.cfg" | Should Contain "^d-i target/storage string sd$"
                "$source/preseed.cfg" | Should Contain "^d-i network/interface string wlan$"
                "$source/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"
                "$source/preseed.cfg" | Should Contain "^d-i network/ssid string Network 1$"
                "$source/preseed.cfg" | Should Contain "^d-i network/wlan_keytype string 1$"
                "$source/preseed.cfg" | Should Contain "^d-i network/wlan_key string 123456$"

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force
            }
        }
    }
}
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Install-OSMCInstaller" -Tags "CI" {
        BeforeAll {
            $SkipTests = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $SkipTests = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Associate($SDDevicePath, $SDDeviceFilePath)
        }

        Context "Raspberry Pi A, B, B+" {
            BeforeAll {
                $FilePath = Get-ChildItem -Path '/downloads' -Filter "OSMC_TGT_rbp1_*.img.gz" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $SkipTests = $true
                }
            }

            It "Should be able to install SD" -Skip:$SkipTests {
                Install-OSMCInstaller -SDDevicePath $SDDevicePath -FilePath $FilePath

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"

                $SD.GetPartition(1) | Should Be $null

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp1$"

                "$mountpoint/config.txt" | Should Contain "^disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$mountpoint/config.txt" | Should Contain "^gpu_mem=16$"

                "$mountpoint/preseed.cfg" | Should Contain "^d-i target/storage string sd$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/interface string eth$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }

                Remove-Item -Path $mountpoint -Recurse -Force
            }

            It "Should be able to install USB and configure wireless network" -Skip:$SkipTests {
                Install-OSMCInstaller -SDDevicePath $SDDevicePath -FilePath $FilePath -USB -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'Network 1'

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"

                $SD.GetPartition(1) | Should Be $null

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp1$"

                "$mountpoint/config.txt" | Should Contain "^disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$mountpoint/config.txt" | Should Contain "^gpu_mem=16$"

                "$mountpoint/preseed.cfg" | Should Contain "^d-i target/storage string usb$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/interface string wlan$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/ssid string Network 1$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/wlan_keytype string 1$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/wlan_key string 123456$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }

                Remove-Item -Path $mountpoint -Recurse -Force
            }
        }

        Context "Raspberry Pi A, B, B+" {
            BeforeAll {
                $FilePath = Get-ChildItem -Path '/downloads' -Filter "OSMC_TGT_rbp2_*.img.gz" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $SkipTests = $true
                }
            }

            It "Should be able to install SD" -Skip:$SkipTests {
                Install-OSMCInstaller -SDDevicePath $SDDevicePath -FilePath $FilePath

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"

                $SD.GetPartition(1) | Should Be $null

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp2$"

                "$mountpoint/config.txt" | Should Contain "^disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$mountpoint/config.txt" | Should Contain "^gpu_mem=16$"

                "$mountpoint/preseed.cfg" | Should Contain "^d-i target/storage string sd$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/interface string eth$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }

                Remove-Item -Path $mountpoint -Recurse -Force
            }

            It "Should be able to install USB and configure wireless network" -Skip:$SkipTests {
                Install-OSMCInstaller -SDDevicePath $SDDevicePath -FilePath $FilePath -USB -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'Network 1'

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"

                $SD.GetPartition(1) | Should Be $null

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/filesystem.tar.xz" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^dwc_otg.fiq_fix_enable=1 sdhci-bcm2708.sync_after_dma=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/ram0 quiet init=/init loglevel=2 osmcdev=rbp2$"

                "$mountpoint/config.txt" | Should Contain "^disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^framebuffer_depth=32$"
                "$mountpoint/config.txt" | Should Contain "^gpu_mem=16$"

                "$mountpoint/preseed.cfg" | Should Contain "^d-i target/storage string usb$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/interface string wlan$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/auto boolean true$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/ssid string Network 1$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/wlan_keytype string 1$"
                "$mountpoint/preseed.cfg" | Should Contain "^d-i network/wlan_key string 123456$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }

                Remove-Item -Path $mountpoint -Recurse -Force
            }
        }

        AfterAll {
            if (-not $SkipTests) {
                [Losetup]::Disassociate($SDDevicePath)
            }
        }
    }
}
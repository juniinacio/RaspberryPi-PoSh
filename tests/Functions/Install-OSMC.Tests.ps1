Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Install-OSMC" -Tags "CI" {
        BeforeAll {
            $SkipTests = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $SkipTests = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Associate($SDDevicePath, $SDDeviceFilePath)

            $USBDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "USB-4gb.img"
            if (-not (Test-Path -Path $USBDeviceFilePath -PathType Leaf)) {
                $SkipTests = $true
                return
            }

            $USBDevicePath = [Losetup]::Lookup()

			[Losetup]::Associate($USBDevicePath, $USBDeviceFilePath)

            $RestoreFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'assets/RestoreFileOSMC.tar'
        }

        Context "Raspberry Pi A, B, B+" {
            BeforeAll {
                $FilePath = Get-ChildItem -Path '/downloads' -Filter "OSMC_TGT_rbp1_*.img.gz" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $skipTests = $true
                }

                $CustomSettings = @{
                    arm_freq = 1000
                    core_freq = 500
                    sdram_freq = 600
                    over_voltage = 6
                    temp_limit = 80
                }
            }

            It "Should be able to install SD" -Skip:$SkipTests {
                Install-OSMC -SDDevicePath $SDDevicePath -FilePath $FilePath

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"
                ($SD.GetPartition(1)).Label | Should Be "STORAGE"
                ($SD.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp1$"

                "$mountpoint/config.txt" | Should Contain "^  arm_freq=850$"
                "$mountpoint/config.txt" | Should Contain "^  core_freq=375$"
                "$mountpoint/config.txt" | Should Contain "^  gpu_mem_256=112$"
                "$mountpoint/config.txt" | Should Contain "^  gpu_mem_512=144$"
                "$mountpoint/config.txt" | Should Contain "^  hdmi_ignore_cec_init=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^  start_x=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_splash=1$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }

                Remove-Item -Path $mountpoint -Recurse -Force
            }

            It "Should be able to install SD using custom settings" -Skip:$SkipTests {
                Install-OSMC -SDDevicePath $SDDevicePath -FilePath $FilePath -CustomSettings $CustomSettings

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"
                ($SD.GetPartition(1)).Label | Should Be "STORAGE"
                ($SD.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp1$"

                "$mountpoint/config.txt" | Should Contain "^  arm_freq=1000$"
                "$mountpoint/config.txt" | Should Contain "^  core_freq=500$"
                "$mountpoint/config.txt" | Should Contain "^  gpu_mem_256=112$"
                "$mountpoint/config.txt" | Should Contain "^  gpu_mem_512=144$"
                "$mountpoint/config.txt" | Should Contain "^  hdmi_ignore_cec_init=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^  start_x=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_splash=1$"
                "$mountpoint/config.txt" | Should Contain "^  sdram_freq=600$"
                "$mountpoint/config.txt" | Should Contain "^  over_voltage=6$"
                "$mountpoint/config.txt" | Should Contain "^  temp_limit=80$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }
            }

            It "Should be able to install USB" -Skip:$SkipTests {
                Install-OSMC -SDDevicePath $SDDevicePath -USBDevicePath $USBDevicePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "Storage"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $USB = [DeviceService]::GetDevice($USBDevicePath)

                ($USB.GetPartition(0)).Label | Should Be "STORAGE"
                ($USB.GetPartition(0)).FSType | Should Be "ext4"

                $USB.GetPartition(1) | Should Be $null

                [Utility]::Mount($USB.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/home/osmc/.kodi/addons" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/home/osmc/.kodi/userdata/guisettings.xml" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bin" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/boot" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/dev" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/etc" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/home" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/lib" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/lib64" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/media" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/mnt" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/opt" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/proc" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/root" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/run" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/sbin" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/selinux" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/srv" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/sys" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/tmp" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/usr" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/var" -PathType Container | Should Be $true

                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }
            }
        }

        Context "Raspberry Pi 2, 3" {
            BeforeAll {
                $FilePath = Get-ChildItem -Path '/downloads' -Filter "OSMC_TGT_rbp2_*.img.gz" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $skipTests = $true
                }

                $CustomSettings = @{
                    max_usb_current = 1
                    gpu_mem = 320
                    gpu_mem_1024 = 320
                }
            }

            It "Should be able to install SD" -Skip:$SkipTests {
                Install-OSMC -SDDevicePath $SDDevicePath -FilePath $FilePath

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"
                ($SD.GetPartition(1)).Label | Should Be "STORAGE"
                ($SD.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp2$"

                "$mountpoint/config.txt" | Should Contain "^  gpu_mem_1024=256$"
                "$mountpoint/config.txt" | Should Contain "^  hdmi_ignore_cec_init=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^  start_x=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_splash=1$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }

                Remove-Item -Path $mountpoint -Recurse -Force
            }

            It "Should be able to install SD using custom settings" -Skip:$SkipTests {
                Install-OSMC -SDDevicePath $SDDevicePath -FilePath $FilePath -CustomSettings $CustomSettings

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $SD = [DeviceService]::GetDevice($SDDevicePath)

                ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
                ($SD.GetPartition(0)).FSType | Should Be "vfat"
                ($SD.GetPartition(1)).Label | Should Be "STORAGE"
                ($SD.GetPartition(1)).FSType | Should Be "ext4"

                [Utility]::Mount($SD.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/kernel.img" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bootcode.bin" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/cmdline.txt" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/config.txt" -PathType Leaf | Should Be $true

                "$mountpoint/cmdline.txt" | Should Contain "^root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp2$"

                "$mountpoint/config.txt" | Should Contain "^  gpu_mem_1024=320$"
                "$mountpoint/config.txt" | Should Contain "^  hdmi_ignore_cec_init=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_overscan=1$"
                "$mountpoint/config.txt" | Should Contain "^  start_x=1$"
                "$mountpoint/config.txt" | Should Contain "^  disable_splash=1$"
                "$mountpoint/config.txt" | Should Contain "^  max_usb_current=1$"
                "$mountpoint/config.txt" | Should Contain "^  gpu_mem=320$"

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(0).Umount()) {
                    [Utility]::Umount($SD.GetPartition(0))
                }
            }

            It "Should be able to install USB" -Skip:$SkipTests {
                Install-OSMC -SDDevicePath $SDDevicePath -USBDevicePath $USBDevicePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

                $mountpoint = Join-Path -Path $TestDrive -ChildPath "Storage"

                $null = New-Item -Path $mountpoint -ItemType Directory

                $USB = [DeviceService]::GetDevice($USBDevicePath)

                ($USB.GetPartition(0)).Label | Should Be "STORAGE"
                ($USB.GetPartition(0)).FSType | Should Be "ext4"

                $USB.GetPartition(1) | Should Be $null

                [Utility]::Mount($USB.GetPartition(0), $mountpoint)

                Test-Path -Path "$mountpoint/home/osmc/.kodi/addons" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/home/osmc/.kodi/userdata/guisettings.xml" -PathType Leaf | Should Be $true
                Test-Path -Path "$mountpoint/bin" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/boot" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/dev" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/etc" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/home" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/lib" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/lib64" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/media" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/mnt" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/opt" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/proc" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/root" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/run" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/sbin" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/selinux" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/srv" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/sys" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/tmp" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/usr" -PathType Container | Should Be $true
                Test-Path -Path "$mountpoint/var" -PathType Container | Should Be $true

                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }
            }
        }

        AfterAll {
            if (-not $SkipTests) {
                [Losetup]::Disassociate($SDDevicePath)
                [Losetup]::Disassociate($USBDevicePath)
            }
        }
    }
}
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Install-OSMC" -Tags "CI" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Attach($SDDevicePath, $SDDeviceFilePath)

            $USBDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "USB-4gb.img"
            if (-not (Test-Path -Path $USBDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $USBDevicePath = [Losetup]::Lookup()

			[Losetup]::Attach($USBDevicePath, $USBDeviceFilePath)

            $FilePath = Get-ChildItem -Path '/downloads' -Filter "OSMC_TGT_rbp2_*.img.gz" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

            $RestoreFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'assets/RestoreFileOSMC.tar'
        }

        It "Should be able to install SD" -Skip:$Skip {
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

            "$mountpoint/cmdline.txt" | Should Contain "^root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet osmcdev=rbp2$"

            # "$mountpoint/config.txt" | Should Contain "^  gpu_mem_1024=256$"
            # "$mountpoint/config.txt" | Should Contain "^  hdmi_ignore_cec_init=1$"
            # "$mountpoint/config.txt" | Should Contain "^  disable_overscan=1$"
            # "$mountpoint/config.txt" | Should Contain "^  start_x=1$"
            # "$mountpoint/config.txt" | Should Contain "^  disable_splash=1$"

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }
        }

        It "Should be able to install USB" -Skip:$Skip {
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

        AfterAll {
            if (-not $Skip) {
                [Losetup]::Detach($SDDevicePath)
                [Losetup]::Detach($USBDevicePath)
            }
        }
    }
}
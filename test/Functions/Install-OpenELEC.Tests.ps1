Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Install-OpenELEC" -Tags "CI" {
		BeforeAll {
			$SkipTests = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $SkipTests = $true
                return
            }

			$SDDevicePath = [Losetup]::Lookup()

			[Losetup]::Attach($SDDevicePath, $SDDeviceFilePath)

			$USBDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "USB-4gb.img"
			if (-not (Test-Path -Path $USBDeviceFilePath -PathType Leaf)) {
                $SkipTests = $true
                return
            }

			$USBDevicePath = [Losetup]::Lookup()

			[Losetup]::Attach($USBDevicePath, $USBDeviceFilePath)

			$RestoreFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'assets/RestoreFileELEC.tar'
		}

		Context "Raspberry Pi A, B, B+" {
			BeforeAll {
                $FilePath = Get-ChildItem -Path '/downloads' -Filter "OpenELEC-RPi.arm-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
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
				Install-OpenELEC -SDDevicePath $SDDevicePath -FilePath $FilePath -CustomSettings $CustomSettings

				$mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

				$null = New-Item -Path $mountpoint -ItemType Directory

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

				"$mountpoint/config.txt" | Should Contain "^  arm_freq=1000$"
                "$mountpoint/config.txt" | Should Contain "^  core_freq=500$"
                "$mountpoint/config.txt" | Should Contain "^  sdram_freq=600$"
                "$mountpoint/config.txt" | Should Contain "^  over_voltage=6$"
                "$mountpoint/config.txt" | Should Contain "^  temp_limit=80$"

				$SD = [DeviceService]::GetDevice($SDDevicePath)
				if ($SD.GetPartition(0).Umount()) {
					[Utility]::Umount($SD.GetPartition(0))
				}
			}

			It "Should be able to install USB" -Skip:$SkipTests {
				Install-OpenELEC -SDDevicePath $SDDevicePath -USBDevicePath $USBDevicePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

				$mountpoint = Join-Path -Path $TestDrive -ChildPath "Storage"

				$null = New-Item -Path $mountpoint -ItemType Directory

				$USB = [DeviceService]::GetDevice($USBDevicePath)

				($USB.GetPartition(0)).Label | Should Be "STORAGE"
				($USB.GetPartition(0)).FSType | Should Be "ext4"

				$USB.GetPartition(1) | Should Be $null

				[Utility]::Mount($USB.GetPartition(0), $mountpoint)

				Test-Path -Path "$mountpoint/.kodi/addons" -PathType Container | Should Be $true
				Test-Path -Path "$mountpoint/.kodi/userdata/sources.xml" -PathType Leaf | Should Be $true

				$USB = [DeviceService]::GetDevice($USBDevicePath)
				if ($USB.GetPartition(0).Umount()) {
					[Utility]::Umount($USB.GetPartition(0))
				}
			}
		}

		Context "Raspberry Pi 2, 3" {
			BeforeAll {
                $FilePath = Get-ChildItem -Path '/downloads' -Filter "OpenELEC-RPi2.arm-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                if ([string]::IsNullOrEmpty($FilePath)) {
                    $skipTests = $true
                }

                $CustomSettings = @{
					arm_freq = 1000
					core_freq = 500
					sdram_freq = 500
					over_voltage = 2
					temp_limit = 80
					max_usb_current = 1
					gpu_mem = 320
					gpu_mem_1024 = 320
					force_turbo = 1
					boot_delay = 1
				}
            }

			It "Should be able to install SD" -Skip:$SkipTests {
				Install-OpenELEC -SDDevicePath $SDDevicePath -FilePath $FilePath -CustomSettings $CustomSettings

				$mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

				$null = New-Item -Path $mountpoint -ItemType Directory

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

				"$mountpoint/config.txt" | Should Contain "^  force_turbo=1$"
				"$mountpoint/config.txt" | Should Contain "^  max_usb_current=1$"
				"$mountpoint/config.txt" | Should Contain "^  gpu_mem=320$"
				"$mountpoint/config.txt" | Should Contain "^  gpu_mem_1024=320$"
				"$mountpoint/config.txt" | Should Contain "^  temp_limit=80$"

				$SD = [DeviceService]::GetDevice($SDDevicePath)
				if ($SD.GetPartition(0).Umount()) {
					[Utility]::Umount($SD.GetPartition(0))
				}
			}

			It "Should be able to install USB" -Skip:$SkipTests {
				Install-OpenELEC -SDDevicePath $SDDevicePath -USBDevicePath $USBDevicePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

				$mountpoint = Join-Path -Path $TestDrive -ChildPath "Storage"

				$null = New-Item -Path $mountpoint -ItemType Directory

				$USB = [DeviceService]::GetDevice($USBDevicePath)

				($USB.GetPartition(0)).Label | Should Be "STORAGE"
				($USB.GetPartition(0)).FSType | Should Be "ext4"

				$USB.GetPartition(1) | Should Be $null

				[Utility]::Mount($USB.GetPartition(0), $mountpoint)

				Test-Path -Path "$mountpoint/.kodi/addons" -PathType Container | Should Be $true
				Test-Path -Path "$mountpoint/.kodi/userdata/sources.xml" -PathType Leaf | Should Be $true

				$USB = [DeviceService]::GetDevice($USBDevicePath)
				if ($USB.GetPartition(0).Umount()) {
					[Utility]::Umount($USB.GetPartition(0))
				}
			}
		}

		AfterAll {
			if (-not $SkipTests) {
                [Losetup]::Detach($SDDevicePath)
                [Losetup]::Detach($USBDevicePath)
            }
		}
    }
}
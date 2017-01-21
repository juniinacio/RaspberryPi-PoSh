Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Install-Plugin" -Tags "CI" {
        BeforeAll {
            $SDDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $(4gb/1048576))
            $SDDevicePath = '/dev/loop0'
            
            $USBDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "USB-8gb.img"
            [Utility]::DD('/dev/zero', $USBDeviceFilePath, 1048576, $(8gb/1048576))
            $USBDevicePath = '/dev/loop1'

            $Path = $env:HOME
			if ($env:USER -eq 'root') {
				$Path = Join-Path -Path '/home' -ChildPath ([Utility]::Who())
			}

            $FilePath = Join-Path -Path $Path -ChildPath 'Downloads/LibreELEC-RPi2.arm-7.0.3.tar'

            $RestoreFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'assets/RestoreFileELEC.tar'

            $Plugins = Get-ChildItem -Path $Env:HOME -Filter "Downloads/plugin.video.*.zip" | Select-Object -ExpandProperty FullName

            Install-LibreELEC -SDDevicePath $SDDevicePath -SDDeviceFilePath $SDDeviceFilePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Losetup]::Attach($SD, $SDDeviceFilePath)
        }

        It "Should be able to install SD" {
            $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

            $null = New-Item -Path $mountpoint -ItemType Directory
            
            $Plugins | Install-Plugin -SDDevicePath $SDDevicePath

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SD.GetPartition(1), $mountpoint)

            Test-Path -Path "$mountpoint/.kodi/addons/plugin.video.youtube" -PathType Container | Should Be $true
            Test-Path -Path "$mountpoint/.kodi/addons/plugin.video.youtube/addon.xml" -PathType Leaf | Should Be $true

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(1).Umount()) {
                [Utility]::Umount($SD.GetPartition(1))
            }
        }

        AfterAll {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Detach($SD)
        }
    }
}
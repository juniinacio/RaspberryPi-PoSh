Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Install-Plugin" -Tags "CI" {
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

            $Plugins = Get-ChildItem -Path '/downloads' -Filter "plugin.video.*.zip" | Select-Object -ExpandProperty FullName

            Install-LibreELEC -SDDevicePath $SDDevicePath -SDDeviceFilePath $SDDeviceFilePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Losetup]::Attach($SD, $SDDeviceFilePath)
        }

        It "Should be able to install SD" -Skip:$Skip {
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
            if (-not $Skip) {
                $SD = [DeviceService]::GetDevice($SDDevicePath)
                [Losetup]::Detach($SD)
            }
        }
    }
}
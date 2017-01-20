Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Backup-Raspberry" -Tags "CI" {
        BeforeAll {
            $SDDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $(4gb/1048576))
            $SDDevicePath = [Losetup]::Lookup()

            $FilePath = Join-Path -Path $Env:HOME -ChildPath 'Downloads/LibreELEC-RPi2.arm-7.0.3.tar'

            $RestoreFilePath = Join-Path -Path $Env:HOME -ChildPath 'Backups/LibreELEC-20170113131100.tar'

            Install-LibreELEC -SDDevicePath $SDDevicePath -SDDeviceFilePath $SDDeviceFilePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)
        }

        It "Should be able to create backup" {

            $Path = Join-Path -Path $TestDrive -ChildPath 'LibreELEC.tar'

            Backup-Raspberry -SDDevicePath $SDDevicePath -Path $Path

            [Tar]::TarInfo($Path) -contains './.kodi/userdata/' | Should Be $true
            [Tar]::TarInfo($Path) -contains './.kodi/addons/' | Should Be $true
        }

        AfterAll {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Detach($SD)
        }
    }
}
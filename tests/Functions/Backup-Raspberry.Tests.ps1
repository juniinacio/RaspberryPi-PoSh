Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Backup-Raspberry" -Tags "CI" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Associate($SDDevicePath, $SDDeviceFilePath)

            $FilePath = Get-ChildItem -Path '/downloads' -Filter "LibreELEC-RPi2.arm-*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName

            $RestoreFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'assets/RestoreFileELEC.tar'

            Install-LibreELEC -SDDevicePath $SDDevicePath -FilePath $FilePath -RestoreFilePath $RestoreFilePath
        }

        It "Should be able to create backups" -Skip:$Skip {
            $Path = Join-Path -Path $TestDrive -ChildPath 'LibreELEC.tar'

            Backup-Raspberry -SDDevicePath $SDDevicePath -Path $Path

            [Tar]::TarInfo($Path) -contains './.kodi/userdata/' | Should Be $true
            [Tar]::TarInfo($Path) -contains './.kodi/addons/' | Should Be $true
        }

        AfterAll {
            if (-not $Skip) {
                [Losetup]::Disassociate($SDDevicePath)
            }
        }
    }
}
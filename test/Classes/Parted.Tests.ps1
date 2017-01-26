Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Parted" -Tags "CI" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }
            
            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Attach($SDDevicePath, $SDDeviceFilePath)

            [DD]::Copy('/dev/zero', $SDDevicePath, 512, 1)

            $SD = [DeviceService]::GetDevice($SDDevicePath)
        }

        It "Should be able to create disk labels" -Skip:$Skip {
            [Parted]::MKLabel($SD, 'msdos') | Should Be $null
        }

        It "Should be able to create partitions" -Skip:$Skip {
            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            $SD.GetPartition(0) | Should Not Be $null
            $SD.GetPartition(1) | Should Not Be $null
        }

        It "Should be able to check partition alignment" -Skip:$Skip {
            [Parted]::Aligncheck($SD, 'opt', 1) | Should Be $true
            [Parted]::Aligncheck($SD, 'opt', 2) | Should Be $true
        }

        It "Should be able to set flags" -Skip:$Skip {
            [Parted]::Set($SD, 1, 'boot', 'on') | Should Not Throw [System.Exception]
        }

        AfterAll {
            if (-not $Skip) {
                [Losetup]::Detach($SDDevicePath)
            }
        }
    }
}
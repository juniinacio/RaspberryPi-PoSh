Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Parted" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/tmp' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }
            
            $SDDevicePath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)

            [Utility]::DD('/dev/zero', $SD.GetPath(), 512, 1)
        }

        It "Should be able to create label" -Skip:$Skip {
            [Parted]::MKLabel($SD, 'msdos') | Should Be $null
        }

        It "Should be able to create partition" -Skip:$Skip {
            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            $SD.GetPartition(0) | Should Not Be $null
            $SD.GetPartition(1) | Should Not Be $null
        }

        It "Should be able to check alignment" -Skip:$Skip {
            [Parted]::Aligncheck($SD, 'opt', 1) | Should Be $true
            [Parted]::Aligncheck($SD, 'opt', 2) | Should Be $true
        }

        It "Should be able to set flag" -Skip:$Skip {
            [Parted]::Set($SD, 1, 'boot', 'on') | Should Not Throw [System.Exception]
        }

        AfterAll {
            if (-not $Skip) {
                $SD = [DeviceService]::GetDevice($SDDevicePath)
                [Losetup]::Detach($SD)
            }
        }
    }
}
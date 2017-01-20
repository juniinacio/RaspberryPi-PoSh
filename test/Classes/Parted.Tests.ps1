Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Parted" {
        BeforeAll {
            $SDDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $(4gb/1048576))
            $SDDevicePath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)
        }

        It "Should be able to create label" {
            [Parted]::MKLabel($SD, 'msdos') | Should Be $null
        }

        It "Should be able to create partition" {
            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            $SD.GetPartition(0) | Should Not Be $null
            $SD.GetPartition(1) | Should Not Be $null
        }

        It "Should be able to check alignment" {
            [Parted]::Aligncheck($SD, 'opt', 1) | Should Be $true
            [Parted]::Aligncheck($SD, 'opt', 2) | Should Be $true
        }

        It "Should be able to set flag" {
            [Parted]::Set($SD, 1, 'boot', 'on') | Should Not Throw [System.Exception]
        }

        AfterAll {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Detach($SD)
        }
    }
}
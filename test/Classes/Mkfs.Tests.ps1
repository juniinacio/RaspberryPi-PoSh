Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Mkfs" {
        BeforeAll {
            $SDDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $(4gb/1048576))
            $SDDevicePath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)

            [Parted]::MKLabel($SD, 'msdos')
            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)
        }

        It "Should be able to create fat filesystem" {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Mkfs]::VFat($SD.GetPartition(0), 'SYSTEM', 32)
            
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
            ($SD.GetPartition(0)).FSType | Should Be "vfat"
        }

        It "Should be able to create ext4 filesystem" {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Mkfs]::Ext4($SD.GetPartition(1), 'STORAGE')

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            ($SD.GetPartition(1)).Label | Should Be "STORAGE"
            ($SD.GetPartition(1)).FSType | Should Be "ext4"
        }

        AfterAll {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Detach($SD)
        }
    }
}
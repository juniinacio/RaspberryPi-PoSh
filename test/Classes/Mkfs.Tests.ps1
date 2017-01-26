Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Mkfs" -Tags "CI" {
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

            [Parted]::MKLabel($SD, 'msdos')
            
            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)
        }

        It "Should be able to create fat filesystems" -Skip:$Skip {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Mkfs]::VFat($SD.GetPartition(0), 'SYSTEM', 32)
            
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            ($SD.GetPartition(0)).Label | Should Be "SYSTEM"
            ($SD.GetPartition(0)).FSType | Should Be "vfat"
        }

        It "Should be able to create ext4 filesystems" -Skip:$Skip {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Mkfs]::Ext4($SD.GetPartition(1), 'STORAGE')

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            ($SD.GetPartition(1)).Label | Should Be "STORAGE"
            ($SD.GetPartition(1)).FSType | Should Be "ext4"
        }

        AfterAll {
            if (-not $Skip) {
                [Losetup]::Detach($SDDevicePath)
            }
        }
    }
}
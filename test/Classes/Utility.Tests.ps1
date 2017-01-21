Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Utility" {
        BeforeAll {
            $SDDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $(4gb/1048576))
            $SDDevicePath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)

            [Parted]::MKLabel($SD, 'msdos')

            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)

            [Parted]::Set($SD, 1, 'boot', 'on')

            [Partprobe]::Probe($SD)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Mkfs]::VFat($SD.GetPartition(0), 'SYSTEM', 32)

            $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

            $null = New-Item -Path $mountpoint -ItemType Directory
        }

        It "Should be able to mount partitions" {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Utility]::Mount($SD.GetPartition(0), $mountpoint)
            
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            ($SD.GetPartition(0)).Umount() | Should Be $true
        }

        It "Should be able to un-mount partitions" {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Utility]::Umount($SD.GetPartition(0))

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            ($SD.GetPartition(0)).Umount() | Should Be $false
        }

        It "Should be able to sync data to persistent storage" {
            [Utility]::Sync() | Should Be $null
        }

        It "Should be able to create disk images" {
            $file = Join-Path -Path $TestDrive -ChildPath 'test.img'
            [Utility]::DD('/dev/zero', $file, 1048576, $(400mb/1048576))
            $file = Get-Item -Path $file
            $file.Length | Should Be 400mb
        }

        It "Should be able to return logged in user" {
            [Utility]::Who() | Should Not Be $null
        }

        AfterAll {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Detach($SD)
        }
    }
}
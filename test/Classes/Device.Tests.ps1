Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Device" {
        $device = [Device]::new('mmcblk0', '', '3904897024', '', 'disk', '', 1)

        $partition = [Device]::new('mmcblk0p1', 'vfat', '533725184', '/media/ubuntu/SYSTEM', 'part', 'SYSTEM', 1)
        $device.SetPartition($partition)

        It "Should be able to return the full path to the device" {
            $device.GetPath() | Should Be '/dev/mmcblk0'
        }

        It "Should be able to return the partition at index 0" {
            $device.GetPartition(0) | Should Not Be $null
        }

        It "Should not be able to return partition at index 1" {
            $device.GetPartition(1) | Should Be $null
        }

        It "Should be able to return the full path to the partition at index 0" {
            $device.GetPartition(0).GetPath() | Should Be '/dev/mmcblk0p1'
        }

        It "Should be able to return the full path to the mountpoint" {
            ($device.GetPartition(0)).Mountpoint | Should Be '/media/ubuntu/SYSTEM'
        }

        It "Should be able to detect that the partition at index 0 is mounted" {
            ($device.GetPartition(0)).Umount() | Should Be $true
        }
    }
}
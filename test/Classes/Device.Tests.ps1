Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Device" {
        $device = [Device]::new('mmcblk0', '', '3904897024', '', 'disk', '', 1)

        $partition = [Device]::new('mmcblk0p1', 'vfat', '533725184', '/media/ubuntu/SYSTEM', 'part', 'SYSTEM', 1)
        $device.SetPartition($partition)

        It "Should be able to return full path to device" {
            $device.GetPath() | Should Be '/dev/mmcblk0'
        }

        It "Should be able to return partition 0" {
            $device.GetPartition(0) | Should Not Be $null
        }

        It "Should be able to return partition 1" {
            $device.GetPartition(1) | Should Be $null
        }

        It "Should be able to return full path to partition 0" {
            $device.GetPartition(0).GetPath() | Should Be '/dev/mmcblk0p1'
        }

        It "Should be able to return full path to mountpoint" {
            ($device.GetPartition(0)).Mountpoint | Should Be '/media/ubuntu/SYSTEM'
        }

        It "(`$device.GetPartition(0)).Umount() should return true" {
            ($device.GetPartition(0)).Umount() | Should Be $true
        }
    }
}
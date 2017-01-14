Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Device" {

        $device = [Device]::new('mmcblk0', '', '3.7G', '', 'disk', '', 1)

        Context "without partitions" {
            It "Can return path to device" {
                $device.GetPath() | Should Be '/dev/mmcblk0'
            }

            It "Cannot return partition 0" {
                $device.GetPartition(0) | Should Be $null
            }
        }

        $partition = [Device]::new('mmcblk0p1', 'vfat', '509M', '/media/ubuntu/SYSTEM', 'part', 'SYSTEM', 1)
        $device.SetPartition($partition)

        Context "with one partition" {
            It "Can return partition 0" {
                $device.GetPartition(0) | Should Not Be $null
            }

            It "Can return path to partition 0" {
                $device.GetPartition(0).GetPath() | Should Be '/dev/mmcblk0p1'
            }

            It "Cannot return partition 1" {
                $device.GetPartition(1) | Should Be $null
            }

            It "Can detect partition 0 is mounted" {
                ($device.GetPartition(0)).Umount() | Should Be $true
                ($device.GetPartition(0)).Mountpoint | Should Be '/media/ubuntu/SYSTEM'
            }
        }

        $partition = [Device]::new('mmcblk0p2', 'ext4', '3.1G', '', 'part', 'STORAGE', 1)
        $device.SetPartition($partition)

        Context "with more than one partition" {
            It "Can return partition 1" {
                $device.GetPartition(0) | Should Not Be $null
            }

            It "Can detect partition 1 is not mounted" {
                ($device.GetPartition(1)).Umount() | Should Be $false
                ($device.GetPartition(1)).Mountpoint | Should Be ''
            }
        }
    }
}
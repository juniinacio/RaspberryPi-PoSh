Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "DeviceService" -Tags "CI" {
        It "Should be able to discover devices" {
            Mock ExecCmd {
                return @'
NAME="sda" FSTYPE="" SIZE="512110190592" MOUNTPOINT="" TYPE="disk" LABEL="" HOTPLUG="0"
NAME="sda1" FSTYPE="ntfs" SIZE="377487360" MOUNTPOINT="" TYPE="part" LABEL="Windows RE tools" HOTPLUG="0"
NAME="sda2" FSTYPE="vfat" SIZE="209715200" MOUNTPOINT="/boot/efi" TYPE="part" LABEL="SYSTEM" HOTPLUG="0"
NAME="sda3" FSTYPE="" SIZE="134217728" MOUNTPOINT="" TYPE="part" LABEL="" HOTPLUG="0"
NAME="sda4" FSTYPE="" SIZE="257698037760" MOUNTPOINT="" TYPE="part" LABEL="" HOTPLUG="0"
NAME="sda5" FSTYPE="" SIZE="253689331712" MOUNTPOINT="" TYPE="part" LABEL="" HOTPLUG="0"
NAME="sdb" FSTYPE="" SIZE="120034123776" MOUNTPOINT="" TYPE="disk" LABEL="" HOTPLUG="1"
NAME="sdb1" FSTYPE="swap" SIZE="24527915520" MOUNTPOINT="[SWAP]" TYPE="part" LABEL="" HOTPLUG="1"
NAME="sdb2" FSTYPE="" SIZE="1024" MOUNTPOINT="" TYPE="part" LABEL="" HOTPLUG="1"
NAME="sdb5" FSTYPE="ext4" SIZE="95427348480" MOUNTPOINT="/" TYPE="part" LABEL="" HOTPLUG="1"
NAME="sdc" FSTYPE="" SIZE="7759462400" MOUNTPOINT="" TYPE="disk" LABEL="" HOTPLUG="1"
NAME="sdc1" FSTYPE="ext4" SIZE="7741636608" MOUNTPOINT="" TYPE="part" LABEL="Storage" HOTPLUG="1"
NAME="loop0" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop0p1" FSTYPE="vfat" SIZE="533725184" MOUNTPOINT="" TYPE="loop" LABEL="SYSTEM" HOTPLUG="0"
NAME="loop0p2" FSTYPE="ext4" SIZE="3743416320" MOUNTPOINT="" TYPE="loop" LABEL="STORAGE" HOTPLUG="0"
NAME="loop1" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop1p1" FSTYPE="vfat" SIZE="254803968" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop2" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop3" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop4" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop5" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop6" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="loop7" FSTYPE="" SIZE="" MOUNTPOINT="" TYPE="loop" LABEL="" HOTPLUG="0"
NAME="mmcblk0" FSTYPE="" SIZE="3904897024" MOUNTPOINT="" TYPE="disk" LABEL="" HOTPLUG="1"
NAME="mmcblk0p1" FSTYPE="vfat" SIZE="533725184" MOUNTPOINT="/tmp/5690122e-d905-4800-a310-f0b8b78b461e" TYPE="part" LABEL="SYSTEM" HOTPLUG="1"
'@
            }

            $devices = [DeviceService]::GetDevices($true)

            $devices.Count | Should Be 12
            $devices[1].Name | Should Be 'sdb'
            $devices[11].Name | Should Be 'mmcblk0'
        }

        It "Should not be able to return device /dev/sda" {
            $devices = [DeviceService]::GetDevices($false)
            $devices | Where-Object {$_.Name -eq 'sda'} | Should Be $null
        }

        It "Should be able to return device /dev/sda" {
            [DeviceService]::GetDevices('sda') | Should Not Be $null
        }
    }
}
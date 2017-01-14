Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "DeviceService" {
        
        Mock ExecCmd {
                    return @'
{
   "blockdevices": [
      {"name": "sda", "fstype": null, "size": "111,8G", "mountpoint": null, "type": "disk", "label": null, "hotplug": "1",
         "children": [
            {"name": "sda1", "fstype": "swap", "size": "22,9G", "mountpoint": "[SWAP]", "type": "part", "label": null, "hotplug": "1"},
            {"name": "sda2", "fstype": null, "size": "1K", "mountpoint": null, "type": "part", "label": null, "hotplug": "1"},
            {"name": "sda5", "fstype": "ext4", "size": "88,9G", "mountpoint": "/", "type": "part", "label": null, "hotplug": "1"}
         ]
      },
      {"name": "sdb", "fstype": null, "size": "477G", "mountpoint": null, "type": "disk", "label": null, "hotplug": "0",
         "children": [
            {"name": "sdb1", "fstype": "ntfs", "size": "360M", "mountpoint": null, "type": "part", "label": "Windows RE tools", "hotplug": "0"},
            {"name": "sdb2", "fstype": "vfat", "size": "200M", "mountpoint": "/boot/efi", "type": "part", "label": "SYSTEM", "hotplug": "0"},
            {"name": "sdb3", "fstype": null, "size": "128M", "mountpoint": null, "type": "part", "label": null, "hotplug": "0"},
            {"name": "sdb4", "fstype": null, "size": "240G", "mountpoint": null, "type": "part", "label": null, "hotplug": "0"},
            {"name": "sdb5", "fstype": null, "size": "236,3G", "mountpoint": null, "type": "part", "label": null, "hotplug": "0"}
         ]
      },
      {"name": "loop0", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop1", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop2", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop3", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop4", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop5", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop6", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "loop7", "fstype": null, "size": null, "mountpoint": null, "type": "loop", "label": null, "hotplug": "0"},
      {"name": "mmcblk0", "fstype": null, "size": "3,7G", "mountpoint": null, "type": "disk", "label": null, "hotplug": "1",
         "children": [
            {"name": "mmcblk0p1", "fstype": "vfat", "size": "509M", "mountpoint": "$TestDrive/SYSTEM", "type": "part", "label": "SYSTEM", "hotplug": "1"},
            {"name": "mmcblk0p2", "fstype": "ext4", "size": "3,1G", "mountpoint": "$TestDrive/STORAGE", "type": "part", "label": "STORAGE", "hotplug": "1"}
         ]
      }
   ]
}
'@
        }

        Context "listing devices" {
            It "Can discover devices" {
                $devices = [DeviceService]::GetDevices($true)

                $devices.Count | Should Be 11
                $devices[1].Name | Should Be 'sdb'
            }

            It "Can discover only removable devices" {
                $devices = [DeviceService]::GetDevices($false)

                $devices.Count | Should Be 10
                $devices | Where-Object {$_.Name -eq 'sdb'} | Should Be $null
            }

            It "Can discover devices including loop devices" {
                $devices = [DeviceService]::GetDevices($false)

                $devices[1].Name | Should Be 'loop0'
                $devices[8].Name | Should Be 'loop7'
            }
        }

        Context "searching devices" {
            It "Can return device /dev/mmcblk0" {
                [DeviceService]::GetDevice('/dev/mmcblk0') | Should Not Be $null
            }

            It "Cannot return device /dev/sdc" {
                [DeviceService]::GetDevice('/dev/sdc') | Should Be $null
            }
        }
    }
}
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Mkfs" {

        $device = [Device]::new('mmcblk0', '', '3.7G', '', 'disk', '', 1)

        $partition = [Device]::new('mmcblk0p1', 'vfat', '509M', '/media/ubuntu/SYSTEM', 'part', 'SYSTEM', 1)
        $device.SetPartition($partition)

        $partition = [Device]::new('mmcblk0p2', 'ext4', '3.1G', '', 'part', 'STORAGE', 1)
        $device.SetPartition($partition)

        Context "building filesystems" {

            Mock ExecCmd {}

            It "Can create fat filesystem" {
                [Mkfs]::VFat($device.GetPartition(0), 'SYSTEM', 32)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'mkfs.vfat' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0p1') `
                                                                -and ($ArgumentsList -contains 'SYSTEM') `
                                                                -and ($ArgumentsList -contains 32) `
                } -Times 1 -Scope It
            }

            It "Can create ext4 filesystem" {
                [Mkfs]::Ext4($device.GetPartition(1), 'STORAGE')

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'mkfs.ext4' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0p2') `
                                                                -and ($ArgumentsList -contains 'STORAGE') `
                                                                -and ($ArgumentsList -contains '-F') `
                } -Times 1 -Scope It
            }
        }
    }
}
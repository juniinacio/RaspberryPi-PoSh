Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Utility" {

        $device = [Device]::new('mmcblk0', '', '3.7G', '', 'disk', '', 1)

        $partition = [Device]::new('mmcblk0p1', 'vfat', '509M', "$TestDrive/SYSTEM", 'part', 'SYSTEM', 1)
        $device.SetPartition($partition)

        $partition = [Device]::new('mmcblk0p2', 'ext4', '3.1G', '', 'part', 'STORAGE', 1)
        $device.SetPartition($partition)

        Context "managing disk partitions" {

            Mock ExecCmd {}

            It "Can mount partition" {
                [Utility]::Mount($device.GetPartition(1), "$TestDrive/STORAGE")
                Assert-MockCalled ExecCmd -ParameterFilter { ($Command -eq 'mount') -and ($ArgumentsList -contains '/dev/mmcblk0p2') } -Times 1 -Scope It
            }

            It "Cannot mount mounted partition" {
                [Utility]::Mount($device.GetPartition(0), "$TestDrive/SYSTEM")
                Assert-MockCalled ExecCmd -Times 0 -Scope It
            }

            It "Can un-mount partition" {
                [Utility]::Umount($device.GetPartition(0))
                Assert-MockCalled ExecCmd -ParameterFilter { ($Command -eq 'umount') -and ($ArgumentsList -contains '/dev/mmcblk0p1') } -Times 1 -Scope It
            }

            It "Cannot un-mount un-mounted partition" {
                [Utility]::Umount($device.GetPartition(1))
                Assert-MockCalled ExecCmd -Times 0 -Scope It
            }
        }

        Context "synchronizing cached writes to persistent storage" {

            Mock ExecCmd {}

            It "Can force data to persistent storage" {
                [Utility]::Sync()
                Assert-MockCalled ExecCmd -ParameterFilter { $Command -eq 'sync' -and ($ArgumentsList.Count -eq 0) } -Times 1 -Scope It
            }
        }

        Context "creating disk images" {

            It "Can create 400mb image" {
                $testFile = Join-Path -Path $TestDrive -ChildPath 'test.img'
                
                [Utility]::DD('/dev/zero', $testFile, 1048576, $(400mb/1048576))

                $file = Get-Item -Path $testFile

                $file.Length | Should Be 400mb
            }
        }

        Context "locating commands" {

            It "Can locate lsblk" {
                [Utility]::Which('lsblk') | Should Match '/lsblk$'
            }

            It "Can locate gzip" {
                [Utility]::Which('gzip') | Should Match '/gzip$'
            }

            It "Can locate losetup" {
                [Utility]::Which('losetup') | Should Match '/losetup$'
            }

            It "Can locate md5sum" {
                [Utility]::Which('md5sum') | Should Match '/md5sum$'
            }

            It "Can locate mkfs" {
                [Utility]::Which('mkfs.vfat') | Should Match '/mkfs.vfat$'
                [Utility]::Which('mkfs.ext4') | Should Match '/mkfs.ext4$'
            }

            It "Can locate parted" {
                [Utility]::Which('parted') | Should Match '/parted$'
            }

            It "Can locate partprobe" {
                [Utility]::Which('partprobe') | Should Match '/partprobe$'
            }

            It "Can locate tar" {
                [Utility]::Which('tar') | Should Match '/tar$'
            }

            It "Can locate unzip" {
                [Utility]::Which('unzip') | Should Match '/unzip$'
            }

            It "Can locate mount" {
                [Utility]::Which('mount') | Should Match '/mount$'
            }

            It "Can locate umount" {
                [Utility]::Which('umount') | Should Match '/umount$'
            }

            It "Can locate sync" {
                [Utility]::Which('sync') | Should Match '/sync$'
            }

            It "Can locate dd" {
                [Utility]::Which('dd') | Should Match '/dd$'
            }
        }
    }
}
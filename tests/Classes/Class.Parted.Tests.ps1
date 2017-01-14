Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Parted" {

        $device = [Device]::new('mmcblk0', '', '3.7G', '', 'disk', '', 1)

        Context "manipulating disk partitions" {

            Mock ExecCmd {}

            It "Can create label" {
                [Parted]::MKLabel($device, 'msdos')

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'parted' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0') `
                                                                -and ($ArgumentsList -contains 'mklabel') `
                                                                -and ($ArgumentsList -contains 'msdos') `
                } -Times 1 -Scope It
            }

            It "Can create partition" {
                [Parted]::MKPart($device, 'primary', 'cyl', 'fat32', 0, 65)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'parted' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0') `
                                                                -and ($ArgumentsList -contains 'primary') `
                                                                -and ($ArgumentsList -contains 'cyl') `
                                                                -and ($ArgumentsList -contains 'fat32') `
                                                                -and ($ArgumentsList -contains '--') `
                                                                -and ($ArgumentsList -contains '0') `
                                                                -and ($ArgumentsList -contains '65') `
                } -Times 1 -Scope It
            }

            It "Can check alignment" {
                [Parted]::Aligncheck($device, 'opt', 1)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'parted' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0') `
                                                                -and ($ArgumentsList -contains 'align-check') `
                                                                -and ($ArgumentsList -contains 1) `
                } -Times 1 -Scope It
            }

            It "Can set flag" {
                [Parted]::Set($device, 1, 'boot', 'on')

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'parted' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0') `
                                                                -and ($ArgumentsList -contains 1) `
                                                                -and ($ArgumentsList -contains 'boot') `
                                                                -and ($ArgumentsList -contains 'on') `
                } -Times 1 -Scope It
            }
        }
    }
}
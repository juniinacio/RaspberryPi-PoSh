Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Losetup" {

        Context "finding loop devices" {

            It "Can return free loop device" {
                $device = [Losetup]::Lookup()
                $device | Should Match "^/dev/loop\d+$"
                $device | Should Not Be $null
            }
        }

        Context "attach/detach loop devices" {

            It "Can attach loop device" {
                Mock Test-Path { return $true }
                Mock ExecCmd {}

                $file = Join-Path -Path $PSScriptRoot -ChildPath '../TestsFiles/sample.img'
                
                [Losetup]::Attach('/dev/loop0', $file)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'losetup' `
                                                                -and $ArgumentsList -contains '/dev/loop0' `
                                                                -and $ArgumentsList -contains $file
                } -Times 1 -Scope It
            }

            It "Can detach loop device" {
                Mock ExecCmd {}

                [Losetup]::Detach('/dev/loop0')

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'losetup' `
                                                                -and $ArgumentsList -contains '-d' `
                                                                -and $ArgumentsList -contains '/dev/loop0'
                } -Times 1 -Scope It
                
            }
        }
    }
}
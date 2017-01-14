Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Md5sum" {

        Context "validating files" {

            It "Can check file in path" {
                Mock ExecCmd {}
                Mock Set-Location {}

                [Md5sum]::Check("$timestamp`.txt")

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'md5sum' `
                                                                -and ($ArgumentsList -contains '-c') `
                                                                -and ($ArgumentsList -contains "$timestamp`.txt")
                } -Times 1 -Scope It
                
                Assert-MockCalled Set-Location -Times 0 -Scope It
            }

            It "Can check file in other path" {
                Mock ExecCmd {}
                Mock Set-Location {}

                [Md5sum]::Check("/tmp/pester/$timestamp`.txt")

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'md5sum' `
                                                                -and ($ArgumentsList -contains '-c') `
                                                                -and ($ArgumentsList -contains "$timestamp`.txt")
                } -Times 1 -Scope It
                
                Assert-MockCalled Set-Location -Times 1 -Scope It
            }
        }
    }
}
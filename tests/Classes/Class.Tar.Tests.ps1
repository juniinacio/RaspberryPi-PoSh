Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Tar" {

        $timestamp = Get-Date -Format 'yyyyMMddmmss'

        Context "extracting files" {

            It "Can extract information" {
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.backup.tar'
                
                [Tar]::TarInfo($filePath) -contains './.kodi/userdata/' | Should Be $true
                [Tar]::TarInfo($filePath) -contains './.kodi/userdata/addon_data/' | Should Be $true
                [Tar]::TarInfo($filePath) -contains './.kodi/addons/' | Should Be $true
            }

            It "Can extract content" {
                Mock Test-Path { return $true }
                Mock ExecCmd {}

                [Tar]::Extract("$TestDrive/$timestamp`.tar", "$TestDrive/$timestamp")

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'tar' `
                                                                -and ($ArgumentsList -contains '-xf') `
                                                                -and ($ArgumentsList -contains "$TestDrive/$timestamp`.tar") `
                                                                -and ($ArgumentsList -contains '-C') `
                                                                -and ($ArgumentsList -contains "$TestDrive/$timestamp") `
                } -Times 1 -Scope It
            }
        }

        Context "storing files" {

            It "Can compress folder" {
                Mock Test-Path { return $true }
                Mock Set-Location {}
                Mock Pop-Location {}
                Mock ExecCmd {}

                [Tar]::Create("$TestDrive/Folder", "$TestDrive/$timestamp`.tar")

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'tar' `
                                                                -and ($ArgumentsList -contains '-cf') `
                                                                -and ($ArgumentsList -contains "$TestDrive/$timestamp`.tar") `
                                                                -and ($ArgumentsList -contains '.') `
                } -Times 1 -Scope It
            }

            It "Can compress folder excluding patterns listed in file" {
                Mock Test-Path { return $true }
                Mock Set-Location {}
                Mock Pop-Location {}
                Mock ExecCmd {}

                [Tar]::CreateEx("$TestDrive/Folder", "$TestDrive/$timestamp`.tar", "$TestDrive/$timestamp`.txt")

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'tar' `
                                                                -and ($ArgumentsList -contains '-cf') `
                                                                -and ($ArgumentsList -contains "$TestDrive/$timestamp`.tar") `
                                                                -and ($ArgumentsList -contains '-X') `
                                                                -and ($ArgumentsList -contains "$TestDrive/$timestamp`.txt") `
                                                                -and ($ArgumentsList -contains '.') `
                } -Times 1 -Scope It
            }
        }
    }
}
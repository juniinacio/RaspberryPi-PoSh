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
            $devicePath = [Losetup]::Lookup()

            $device = [DeviceService]::GetDevice($devicePath)

            It "Can attach loop device" {
                Mock Test-Path { return $true }
                Mock ExecCmd {}

                $file = Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.img'
                
                [Losetup]::Attach($device, $file)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'losetup' `
                                                                -and $ArgumentsList -contains $devicePath `
                                                                -and $ArgumentsList -contains $file
                } -Times 1 -Scope It
            }

            It "Can detach loop device" {
                Mock ExecCmd {}

                [Losetup]::Detach($device)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'losetup' `
                                                                -and $ArgumentsList -contains '-d' `
                                                                -and $ArgumentsList -contains $devicePath
                } -Times 1 -Scope It
                
            }
        }
    }
}
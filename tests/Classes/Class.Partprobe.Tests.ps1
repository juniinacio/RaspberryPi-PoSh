Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Partprobe" {

        $device = [Device]::new('mmcblk0', '', '3.7G', '', 'disk', '', 1)

        Context "informing the OS of partition table changes" {

            Mock ExecCmd {}

            It "Can inform the kernel" {
                [Partprobe]::Probe($device)

                Assert-MockCalled ExecCmd -ParameterFilter {    $Command -eq 'partprobe' `
                                                                -and ($ArgumentsList -contains '/dev/mmcblk0')
                } -Times 1 -Scope It
            }
        }
    }
}
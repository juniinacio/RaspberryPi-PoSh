Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psm1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "ConfigFile" -Tags "CI" {

        BeforeEach {
            $file = Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'assets\config.txt') -Destination $TestDrive -PassThru -Force
        }

        It "Should be able to add settings" {
            $customSettings = @{
                max_usb_current = 1
            }

            $config = [Config]::new($TestDrive)
            $config.SetCustomSettings($customSettings)
            $config.Save()

            $file | Should Contain "^  max_usb_current=1$"
        }

        It "Should be able to update settings" {
            $customSettings = @{
                initial_turbo = 30
                gpu_mem = 320
				gpu_mem_1024 = 320
            }

            $config = [Config]::new($TestDrive)
            $config.SetCustomSettings($customSettings)
            $config.Save()

            $file | Should Contain "^  initial_turbo=30$"
            $file | Should Contain "^  gpu_mem=320$"
        }
    }
}
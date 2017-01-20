Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "ConfigFile" -Tags "CI" {

        BeforeEach {
            $file = Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'assets\config.txt') -Destination $TestDrive -PassThru -Force
        }

        It "Should be able to add missing settings" {
            $customSettings = @{
                max_usb_current = 1
            }
            
            $configFile = [ConfigFile]::new($TestDrive)
            $configFile.SetCustomSettings($customSettings)
            $configFile.Save()

            $file | Should Contain "^  max_usb_current=1$"
        }

        It "Should be able to update existing settings" {
            $customSettings = @{
                initial_turbo = 30
            }
            
            $configFile = [ConfigFile]::new($TestDrive)
            $configFile.SetCustomSettings($customSettings)
            $configFile.Save()

            $file | Should Contain "^  initial_turbo=30$"
        }
    }
}
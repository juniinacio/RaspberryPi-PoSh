Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "ConfigFile" {

        $testFile = Join-Path -Path $TestDrive -ChildPath "config.txt"

        Context "adding config settings" {

            It "Can add missing settings" {
                Set-Content -Path $testFile -Value @'
# arm_freq=700
# core_freq=250
# sdram_freq=400
# over_voltage=0
'@
                $customSettings = @{
                    hdmi_ignore_cec_init = 1
                    disable_overscan = 1
                }

                $configFile = [ConfigFile]::new($TestDrive)
                $configFile.SetCustomSettings($customSettings)
                $configFile.Save()

                $testFile | Should Contain "^# arm_freq=700$"
                $testFile | Should Contain "^  hdmi_ignore_cec_init=1$"
                $testFile | Should Contain "^  disable_overscan=1$"
            }

            It "Can update existing settings" {
                Set-Content -Path $testFile -Value @'
# arm_freq=700
# core_freq=250
# sdram_freq=400
# over_voltage=0
disable_overscan = 0
'@

                $customSettings = @{
                    force_turbo = 0
                    arm_freq = 1350
                    core_freq = 500
                    over_voltage = 4
                    hdmi_ignore_cec_init = 1
                    disable_overscan = 1
                }

                $configFile = [ConfigFile]::new($TestDrive)
                $configFile.SetCustomSettings($customSettings)
                $configFile.Save()

                $testFile | Should Contain "^  arm_freq=1350$"
                $testFile | Should Contain "^  core_freq=500$"
                $testFile | Should Contain "^  over_voltage=4$"
                $testFile | Should Contain "^# sdram_freq=400$"
                $testFile | Should Contain "^  force_turbo=0$"
                $testFile | Should Contain "^  hdmi_ignore_cec_init=1$"
                $testFile | Should Contain "^  disable_overscan=1$"
            }
        }
    }
}
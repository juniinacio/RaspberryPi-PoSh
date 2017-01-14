Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {

    Describe "PreseedFile" {

        $testFile = "$TestDrive/preseed.cfg"

        Context "setting network settings" {

            It "Can add network setting" {
                $preseedFile = [PreseedFile]::New($TestDrive)

                $preseedFile.SetNetworkSetting('interface', [PreseedOptionType]::PRESEED_STRING, 'wlan')
                $preseedFile.SetNetworkSetting('auto', [PreseedOptionType]::PRESEED_BOOL, 'true')
                
                $preseedFile.Save()

                $testFile | Should Contain "^d-i network/interface string wlan$"
                $testFile | Should Contain "^d-i network/auto boolean true$"
            }
        }

        Context "setting target settings" {

            It "Can add target setting" {
                $preseedFile = [PreseedFile]::New($TestDrive)

                $preseedFile.SetTargetSetting('storage', [PreseedOptionType]::PRESEED_STRING, 'usb')
                
                $preseedFile.Save()

                $testFile | Should Contain "^d-i target/storage string usb$"
            }
        }
    }
}
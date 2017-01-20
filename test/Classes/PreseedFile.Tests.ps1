Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "PreseedFile" {
        BeforeAll {
            $file = Join-Path -Path $TestDrive -ChildPath 'preseed.cfg'
        }

        It "Should be able to add network settings" {
            $preseedFile = [PreseedFile]::New($TestDrive)
            $preseedFile.SetNetworkSetting('interface', [PreseedOptionType]::PRESEED_STRING, 'wlan')
            $preseedFile.SetNetworkSetting('auto', [PreseedOptionType]::PRESEED_BOOL, 'true')
            $preseedFile.Save()
            
            $file | Should Contain "^d-i network/interface string wlan$"
            $file | Should Contain "^d-i network/auto boolean true$"
        }

        It "Should be able to add storage settings" {
            $preseedFile = [PreseedFile]::New($TestDrive)
            $preseedFile.SetTargetSetting('storage', [PreseedOptionType]::PRESEED_STRING, 'usb')
            $preseedFile.Save()

            $file | Should Contain "^d-i target/storage string usb$"
        }
    }
}
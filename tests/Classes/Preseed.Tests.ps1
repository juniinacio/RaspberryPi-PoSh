Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Preseed" -Tags "CI" {
        BeforeAll {
            $file = Join-Path -Path $TestDrive -ChildPath 'preseed.cfg'
        }

        It "Should be able to add network settings" {
            $preseed = [Preseed]::New($TestDrive)
            $preseed.SetNetworkSetting('interface', [PreseedOptionType]::PRESEED_STRING, 'wlan')
            $preseed.SetNetworkSetting('auto', [PreseedOptionType]::PRESEED_BOOL, 'true')
            $preseed.Save()

            $file | Should Contain "^d-i network/interface string wlan$"
            $file | Should Contain "^d-i network/auto boolean true$"
        }

        It "Should be able to add storage settings" {
            $preseed = [Preseed]::New($TestDrive)
            $preseed.SetTargetSetting('storage', [PreseedOptionType]::PRESEED_STRING, 'usb')
            $preseed.Save()

            $file | Should Contain "^d-i target/storage string usb$"
        }
    }
}
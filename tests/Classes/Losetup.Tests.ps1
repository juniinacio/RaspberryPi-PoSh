Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Losetup" -Tags "CI" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()
        }

        It "Should be able to return free loopback device" {
            [Losetup]::Lookup() | Should Match "^/dev/loop\d+$"
        }

        It "Should be able to associate disk images with devices" -Skip:$Skip {
            {[Losetup]::Associate($SDDevicePath, $SDDeviceFilePath) } | Should Not Throw
        }

        It "Should be able to disassociate disk images from devices" -Skip:$Skip {
            { [Losetup]::Disassociate($SDDevicePath) } | Should Not Throw
        }
    }
}
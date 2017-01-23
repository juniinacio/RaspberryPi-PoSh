Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

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

        It "Should be able to attach disk images" -Skip:$Skip {
            {[Losetup]::Attach($SDDevicePath, $SDDeviceFilePath) } | Should Not Throw
        }

        It "Should be able to detach disk images" -Skip:$Skip {
            { [Losetup]::Detach($SDDevicePath) } | Should Not Throw
        }
    }
}
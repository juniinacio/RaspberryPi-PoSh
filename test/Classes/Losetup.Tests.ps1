Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Losetup" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/tmp' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }
            
            $device = [Losetup]::Lookup()
            $device = [DeviceService]::GetDevice($device)
        }

        It "Should be able to return loop device" -Skip:$Skip {
            $device.GetPath() | Should Match "^/dev/loop\d+$"
        }

        It "Should be able to attach image to loop device" -Skip:$Skip {
            {[Losetup]::Attach($device, $SDDeviceFilePath) } | Should Not Throw
        }

        It "Should be able to detach image from loop device" -Skip:$Skip {
            { [Losetup]::Detach($device) } | Should Not Throw
        }
    }
}
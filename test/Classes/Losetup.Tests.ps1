Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Losetup" {
        BeforeAll {
            $file = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $file, 1048576, $(4gb/1048576))
            $device = [Losetup]::Lookup()
            $device = [DeviceService]::GetDevice($device)
        }

        It "Should be able to return loop device" {
            $device.GetPath() | Should Match "^/dev/loop\d+$"
        }

        It "Should be able to attach image to loop device" {
            [Losetup]::Attach($device, $file)
            $device2 = [Losetup]::Lookup()
            $device.GetPath() | Should Not Be $device2
            $output = & losetup
            $output -match ("(?m){0}" -f $device.GetPath()) | Should Be $true
        }

        It "Should be able to detach image from loop device" {
            [Losetup]::Detach($device)
            $output = & losetup
            $output -match ("(?m){0}" -f $device.GetPath()) | Should Not Be $true
        }
    }
}
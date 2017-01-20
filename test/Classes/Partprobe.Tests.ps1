Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Partprobe" {
        BeforeAll {
            $SDDeviceFilePath = Join-Path -Path $TestDrive -ChildPath "SD-4gb.img"
            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $(4gb/1048576))
            $SDDevicePath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)
        }

        It "Should be able to inform the kernel of partition table changes" {
            [Partprobe]::Probe($SD) | Should Not Throw [System.Exception]
        }

        AfterAll {
            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Detach($SD)
        }
    }
}
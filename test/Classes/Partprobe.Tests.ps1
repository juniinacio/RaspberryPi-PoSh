Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Partprobe" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/tmp' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            [Losetup]::Attach($SD, $SDDeviceFilePath)

            [Utility]::DD('/dev/zero', $SD.GetPath(), 512, 1)

            [Parted]::MKLabel($SD, 'msdos')

            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)
        }

        It "Should be able to inform the kernel of partition table changes" -Skip:$Skip {
            [Partprobe]::Probe($SD) | Should Not Throw [System.Exception]
        }

        AfterAll {
            if (-not $Skip) {
                $SD = [DeviceService]::GetDevice($SDDevicePath)
                [Losetup]::Detach($SD)
            }
        }
    }
}
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Partprobe" -Tags "CI" {
        BeforeAll {
            $Skip = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $Skip = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Attach($SDDevicePath, $SDDeviceFilePath)

            [DD]::Copy('/dev/zero', $SDDevicePath, 512, 1)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Parted]::MKLabel($SD, 'msdos')

            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)
            [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)
        }

        It "Should be able to inform the kernel if partition table changes" -Skip:$Skip {
            [Partprobe]::Probe($SD) | Should Not Throw [System.Exception]
        }

        AfterAll {
            if (-not $Skip) {
                [Losetup]::Detach($SDDevicePath)
            }
        }
    }
}
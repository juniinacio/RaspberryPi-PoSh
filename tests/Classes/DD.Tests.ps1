Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "DD" -Tags "CI" {
        BeforeAll {
            $SkipTests = $false

            $SDDeviceFilePath = Join-Path -Path '/downloads' -ChildPath "SD-4gb.img"
            if (-not (Test-Path -Path $SDDeviceFilePath -PathType Leaf)) {
                $SkipTests = $true
                return
            }

            $SDDevicePath = [Losetup]::Lookup()

            [Losetup]::Associate($SDDevicePath, $SDDeviceFilePath)

            $File = Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'assets/sample.img.gz') -Destination $TestDrive -PassThru

            [Gzip]::Extract($File.FullName)

            $File = Get-Item -Path (Join-Path -Path $TestDrive -ChildPath $File.BaseName)
        }

        It "Should be able to create disk images" {
            $File = Join-Path -Path $TestDrive -ChildPath 'test.img'
            [DD]::Copy('/dev/zero', $File, 1048576, $(400mb/1048576))
            $File = Get-Item -Path $File
            $File.Length | Should Be 400mb
        }

        It "Should be able to write image to device" -Skip:$SkipTests {
            Start-Sleep -Seconds 5
            $mountpoint = Join-Path -Path $TestDrive -ChildPath "System"

            $null = New-Item -Path $mountpoint -ItemType Directory

            [DD]::Copy($File.FullName, $SDDevicePath, 4mb)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Partprobe]::Probe($SD)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SD.GetPartition(0), $mountpoint)

            Test-Path -Path "$mountpoint/Folder1" -PathType Container | Should Be $true
            Test-Path -Path "$mountpoint/File1" -PathType Leaf | Should Be $true

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }
        }

        AfterAll {
            if (-not $SkipTests) {
                [Losetup]::Disassociate($SDDevicePath)
            }
        }
    }
}
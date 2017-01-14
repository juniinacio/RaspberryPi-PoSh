Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Install-Plugin" {

        Context "installing on LibreELEC/OpenELEC" {

            It "Can install SD" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                $backup = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.backup.tar')

                Install-LibreELEC -SD '/dev/mmcblk0' -FilePath $file.FullName -RestoreFilePath $backup.FullName

                Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "plugin.video.*.zip" | Select-Object -ExpandProperty FullName | Install-Plugin -SD '/dev/mmcblk0'

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(1).Umount()) {
                    [Utility]::Umount($device.GetPartition(1))
                }

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')

                [Utility]::Mount($device.GetPartition(1), $source)

                Test-Path -Path "$source/.kodi/addons/plugin.video.youtube" -PathType Container | Should Be $true
                Test-Path -Path "$source/.kodi/addons/plugin.video.youtube/addon.xml" -PathType Leaf | Should Be $true

                $device = [DeviceService]::GetDevice('/dev/mmcblk0')
                if ($device.GetPartition(1).Umount()) {
                    [Utility]::Umount($device.GetPartition(1))
                }

                Remove-Item -Path $source -Recurse -Force
            }

            It "Can install USB" {
                $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

                $backup = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.backup.tar')

                Install-LibreELEC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath $file.FullName -RestoreFilePath $backup.FullName

                Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "plugin.video.*.zip" | Select-Object -ExpandProperty FullName | Install-Plugin -USB '/dev/sdc'

                $source = "$TestDrive/STORAGE"

                New-Item -Path $source -ItemType Directory | Out-Null

                $device = [DeviceService]::GetDevice('/dev/sdc')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                $device = [DeviceService]::GetDevice('/dev/sdc')

                [Utility]::Mount($device.GetPartition(0), $source)

                Test-Path -Path "$source/.kodi/addons/plugin.video.youtube" -PathType Container | Should Be $true
                Test-Path -Path "$source/.kodi/addons/plugin.video.youtube/addon.xml" -PathType Leaf | Should Be $true

                $device = [DeviceService]::GetDevice('/dev/sdc')
                if ($device.GetPartition(0).Umount()) {
                    [Utility]::Umount($device.GetPartition(0))
                }

                Remove-Item -Path $source -Recurse -Force
            }
        }
    }
}
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Backup-Raspberry" {

        Context "backuping SD" {

            $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

            $backup = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.backup.tar')

            Install-LibreELEC -SD '/dev/mmcblk0' -FilePath $file.FullName -RestoreFilePath $backup.FullName

            It "Can create backup from SD" {
                $timestamp = Get-Date -Format 'yyyyMMddmmss'

                $filePath = "$TestDrive/LibreELEC-$timestamp`.tar"

                Backup-Raspberry -SD '/dev/mmcblk0' -Path $filePath

                [Tar]::TarInfo($filePath) -contains './.kodi/userdata/' | Should Be $true
                [Tar]::TarInfo($filePath) -contains './.kodi/addons/' | Should Be $true
            }
        }

        Context "backuping USB" {
            $file = Get-ChildItem -Path '/home/ubuntu/Downloads/' -Filter "LibreELEC-RPi2*" | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1

            $backup = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.backup.tar')

            Install-LibreELEC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath $file.FullName -RestoreFilePath $backup.FullName

            It "Can create backup from USB" {
                $timestamp = Get-Date -Format 'yyyyMMddmmss'

                $filePath = "$TestDrive/LibreELEC-$timestamp`.tar"

                Backup-Raspberry -USB '/dev/sdc' -Path $filePath

                [Tar]::TarInfo($filePath) -contains './.kodi/userdata/' | Should Be $true
                [Tar]::TarInfo($filePath) -contains './.kodi/addons/' | Should Be $true
            }

            It "Can create backup from USB excluding patterns listed in file" {
                $timestamp = Get-Date -Format 'yyyyMMddmmss'

                $filePath = "$TestDrive/LibreELEC-$timestamp`.tar"

                $excludePath = Join-Path -Path $PSScriptRoot -ChildPath '../Files/excludeFile.txt'

                Backup-Raspberry -USB '/dev/sdc' -Path $filePath -Exclude $excludePath

                [Tar]::TarInfo($filePath) -contains './.kodi/userdata/' | Should Be $false
                [Tar]::TarInfo($filePath) -contains './.kodi/addons/' | Should Be $true
            }
        }
    }
}
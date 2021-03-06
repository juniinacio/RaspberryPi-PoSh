Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Tar" -Tags "CI" {
        BeforeAll {
            $file = Join-Path -Path $PSScriptRoot -ChildPath 'assets/sample.backup.tar'
            $destination = Join-Path -Path $TestDrive -ChildPath "tmp"
            $null = New-Item -Path $destination -ItemType Directory
        }

        It "Should be able to extract content information" {
            [Tar]::TarInfo($file) -contains './.kodi/userdata/' | Should Be $true
            [Tar]::TarInfo($file) -contains './.kodi/userdata/addon_data/' | Should Be $true
            [Tar]::TarInfo($file) -contains './.kodi/addons/' | Should Be $true
        }

        It "Should be able to extract content" {
            [Tar]::Extract($file, $destination)
            Test-Path "$destination/.kodi/addons" -PathType Container | Should Be $true
            Test-Path "$destination/.kodi/userdata/guisettings.xml" -PathType Leaf | Should Be $true
        }

        It "Should be able to compress folder contents" {
            [Tar]::Create($destination, "$TestDrive/backup.tar")
            Test-Path "$TestDrive/backup.tar" -PathType Leaf | Should Be $true
            [Tar]::TarInfo("$TestDrive/backup.tar") -contains './.kodi/userdata/' | Should Be $true
            [Tar]::TarInfo("$TestDrive/backup.tar") -contains './.kodi/addons/' | Should Be $true
        }

        It "Should be able to compress folder contents excluding certain files" {
            [Tar]::Create($destination, "$TestDrive/backup.tar", (Join-Path -Path $PSScriptRoot -ChildPath 'assets/excludeFile.txt'))
            [Tar]::TarInfo("$TestDrive/backup.tar") -contains './.kodi/userdata/' | Should Be $false
            [Tar]::TarInfo("$TestDrive/backup.tar") -contains './.kodi/addons/' | Should Be $true
        }
    }
}
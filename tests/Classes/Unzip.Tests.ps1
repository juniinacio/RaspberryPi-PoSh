Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Unzip" -Tags "CI" {
        It "Should be able to extract content information" {
            $file = Join-Path -Path $PSScriptRoot -ChildPath 'assets/plugin.video.good.zip'
            ([Unzip]::ZipInfo($file) -contains 'plugin.video.good/addon.xml') | Should Be $true
        }

        It "Should be able to extract content" {
            $file = Join-Path -Path $PSScriptRoot -ChildPath 'assets/plugin.video.good.zip'
            [Unzip]::Extract($file, $TestDrive)
            Test-Path -Path "$TestDrive/plugin.video.good/addon.xml" -PathType Leaf | Should Be $true
        }
    }
}
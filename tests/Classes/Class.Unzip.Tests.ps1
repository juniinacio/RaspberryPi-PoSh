Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Unzip" {

        Context "extracting compressed files" {

            It "Can extract information" {
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath '../Files/plugin.video.good.zip'
                
                ([Unzip]::ZipInfo($filePath) -contains 'plugin.video.good/addon.xml') | Should Be $true
            }

            It "Can extract content" {
                $filePath = Join-Path -Path $PSScriptRoot -ChildPath '../Files/plugin.video.good.zip'
                
                [Unzip]::Extract($filePath, $TestDrive)

                Test-Path -Path "$TestDrive/plugin.video.good/addon.xml" -PathType Leaf | Should Be $true
            }
        }
    }
}
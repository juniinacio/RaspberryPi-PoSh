Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    
    Describe "Gzip" {

        Context "uncompressing files" {

            It "Can uncompress file sample.img.gz" {
                $file = Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '../Files/sample.img.gz') -Destination $TestDrive -PassThru
                [Gzip]::Extract($file)

                Test-Path -Path "$TestDrive/sample.img" -PathType Leaf | Should Be $true
            }
        }
    }
}
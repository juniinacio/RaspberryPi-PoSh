Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Md5sum" -Tags "CI" {
        It "Should be able to validate checksum" {
            [Md5sum]::Check((Join-Path -Path $PSScriptRoot -ChildPath 'assets\sample.img.gz.md5')) | Should Not Throw [System.Exception]
        }
    }
}
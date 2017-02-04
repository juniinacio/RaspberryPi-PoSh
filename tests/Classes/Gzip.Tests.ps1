Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

InModuleScope RaspberryPi-PoSh {
    Describe "Gzip" -Tags "CI" {
        It "Should be able to extract content" {
            $file = Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'assets/sample.img.gz') -Destination $TestDrive -PassThru
            [Gzip]::Extract($file.FullName)
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath $file.Basename) -PathType Leaf | Should Be $true
        }
    }
}
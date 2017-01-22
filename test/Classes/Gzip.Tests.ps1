Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')

InModuleScope RaspberryPi-PoSh {
    Describe "Gzip" {
        It "Should be able to extract content" {
            $file = Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'assets/sample.img.gz') -Destination $TestDrive -PassThru
            [Gzip]::Extract($file.FullName)
            Test-Path -Path (Join-Path -Path $TestDrive -ChildPath $file.Basename) -PathType Leaf | Should Be $true
        }
    }
}
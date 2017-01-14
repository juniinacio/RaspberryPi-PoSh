#!/usr/bin/env powershell
[CmdletBinding()]
Param (
)

# Import the module from the current package
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath 'src/Modules/RaspberryPi-PoSh/RaspberryPi-PoSh.psd1')
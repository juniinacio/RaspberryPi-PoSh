#!/usr/bin/env powershell
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FilePath
)

Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

if (-not $PSBoundParameters.ContainsKey('FilePath')) {
    $FilePath = Join-Path -Path $Env:HOME -ChildPath ('Backups/LibreELEC-{0}.tar' -f (Get-Date -format 'yyyyMMddHHmmss'))
}

$params = @{}

$Exclude = Join-Path -Path $PSScriptRoot -ChildPath 'etc/excludes.txt'
if (Test-Path -Path $Exclude -PathType Leaf) {
    $params.Exclude = $Exclude
}

Backup-Raspberry -USB '/dev/sdc' -Path $FilePath @params -Verbose


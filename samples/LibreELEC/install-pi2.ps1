#!/usr/bin/env powershell
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $FilePath
)

Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath '../../RaspberryPi-PoSh/RaspberryPi-PoSh.psd1') -Force

$params = @{}

$params.FilePath = $FilePath
if (-not $PSBoundParameters.ContainsKey('FilePath')) {
    $params.FilePath = Get-ChildItem -Path (Join-Path -Path $env:HOME -ChildPath 'Downloads') -Filter 'LibreELEC-RPi2.arm-*.tar' | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}

$RestoreFile = Get-ChildItem -Path (Join-Path -Path $env:HOME -ChildPath 'Backups') -Filter 'LibreELEC-*.tar' | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
if (Test-Path -Path $RestoreFile -PathType Leaf) {
    $params.RestoreFile = $RestoreFile
}

$customSettings = @{
    arm_freq = 1000
    sdram_freq = 500
    core_freq = 500
    over_voltage = 2
    temp_limit = 80
    max_usb_current = 1
}
$params.CustomSettings = $customSettings

Install-LibreELEC -SD '/dev/mmcblk0' @params -Verbose
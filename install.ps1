#!/usr/bin/env powershell
[CmdletBinding()]
Param (
    # The path to store the module, default /usr/local/share/powershell/Modules
    [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
    [ValidateScript({
        Test-Path -Path $_ -PathType Container
    })]
    [string]
    $Destination
)

if (-not $PSBoundParameters.ContainsKey('Destination')) {
    $Destination = '/usr/local/share/powershell/Modules'
}

if (-not (Test-Path -Path $Destination -PathType Container)) {
    throw "Cannot find path '$Destination' because it does not exist."
}

$moduleName = 'RaspberryPi-PoSh'

$source = Join-Path -Path $PSScriptRoot -ChildPath "src/Modules/$moduleName"

$modulePath = Join-Path -Path $Destination -ChildPath $moduleName

if (Test-Path -Path $modulePath -PathType Container) {
    Remove-Item -Path $modulePath -Force -Recurse
}

Copy-Item -Path $source -Destination $modulePath -Recurse
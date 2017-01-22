#!/usr/bin/env powershell
[CmdletBinding()]
Param (
    # The name of the test to run
    [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TestName
)

Import-Module -Name Pester

$params = @{}

if ($PSBoundParameters.ContainsKey('TestName')) {
    $params.Add('TestName', $TestName)
}

if (-not (Test-Path -Path "$PSScriptRoot/artifacts" -PathType Container)) {
    New-Item -Path "$PSScriptRoot/artifacts" -ItemType Directory | Out-Null
}

dd if=/dev/zero of='/tmp/SD-4gb.img'  bs=1048576  count=$(4gb/1048576) status=none
dd if=/dev/zero of='/tmp/USB-8gb.img'  bs=1048576  count=$(8gb/1048576) status=none

Invoke-Pester -Script "$PSScriptRoot/test" -EnableExit -OutputFile "$PSScriptRoot/artifacts/TestResults.xml" -OutputFormat NUnitXml @params

Remove-Item -Path '/tmp/SD-4gb.img' -Force -EA 0
Remove-Item -Path '/tmp/USB-8gb.img' -Force -EA 0

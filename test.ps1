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

# Create test disk images:
# sudo dd if=/dev/zero of=/downloads/SD-4gb.img  bs=1048576  count=4096 status=none && sudo dd if=/dev/zero of=/downloads/USB-4gb.img  bs=1048576  count=4096 status=none

Invoke-Pester -Script "$PSScriptRoot/test" -EnableExit -OutputFile "$PSScriptRoot/artifacts/TestResults.xml" -OutputFormat NUnitXml @params

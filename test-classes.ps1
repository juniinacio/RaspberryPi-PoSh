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

Invoke-Pester -Script "$PSScriptRoot/tests/Classes" -EnableExit -OutputFile "$PSScriptRoot/artifacts/TestResults.xml" -OutputFormat NUnitXml @params
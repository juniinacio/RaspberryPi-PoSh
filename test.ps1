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

Invoke-Pester -Script "$PSScriptRoot/tests" -EnableExit -OutputFile "$PSScriptRoot/artifacts/TestResults.xml" -OutputFormat NUnitXml @params
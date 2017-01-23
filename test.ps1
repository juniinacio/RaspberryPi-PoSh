#!/usr/bin/env powershell
[CmdletBinding()]
Param (
    # Informs Invoke-Pester to only run Describe blocks that match this name.
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $TestName,

    # Informs Invoke-Pester to only run Describe blocks tagged with the tags specified. Aliased 'Tags' for backwards compatibility.
    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [Alias('Tags')]
    [string[]]
    $Tag
)

Import-Module -Name Pester

$params = @{}

if ($PSBoundParameters.ContainsKey('TestName')) {
    $params.Add('TestName', $TestName)
}

if ($PSBoundParameters.ContainsKey('Tag')) {
    $params.Add('Tag', $Tag)
}

if (-not (Test-Path -Path "$PSScriptRoot/artifacts" -PathType Container)) {
    New-Item -Path "$PSScriptRoot/artifacts" -ItemType Directory | Out-Null
}

# Create test disk images:
# sudo dd if=/dev/zero of=/downloads/SD-4gb.img  bs=1048576  count=4096 status=none && sudo dd if=/dev/zero of=/downloads/USB-4gb.img  bs=1048576  count=4096 status=none

Invoke-Pester -Script "$PSScriptRoot/test" -EnableExit -OutputFile "$PSScriptRoot/artifacts/TestResults.xml" -OutputFormat NUnitXml @params

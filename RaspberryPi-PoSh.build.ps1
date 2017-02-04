# Include: Settings
. './RaspberryPi-PoSh.settings.ps1'

# Include: Utils
. './RaspberryPi-PoSh.utils.ps1'

# Synopsis: Run/Publish Tests and Fail Build on Error
task Test BeforeTest, RunTests, ConfirmTestsPassed, AfterTest

# Synopsis: Run full Pipleline.
task . Clean, Install, Analyze, Test, Archive, Publish

# Synopsis: Install Build Dependencies
task InstallDependencies {
    # Cant run an Invoke-Build Task without Invoke-Build.
    Install-Module -Name InvokeBuild -Force
    # Install-Module -Name Pester -Force
    Install-Module -Name PSScriptAnalyzer -Force
}

# Synopsis: Clean Artifacts Directory
task Clean BeforeClean, {
    if (Test-Path -Path $Artifacts) {
        Remove-Item "$Artifacts/*" -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path $Artifacts -Force

    if (Test-Path -Path "$ModulesPath/$ModuleName") {
        Remove-Item -Path "$ModulesPath/$ModuleName/*" -Recurse -Force
    }
    $null = New-Item -ItemType Directory -Path "$ModulesPath/$ModuleName" -Force
}, AfterClean

# Synopsis: Install Module Locally
task Install {
    Copy-Item -Path "$ModulePath/*" -Destination "$ModulesPath/$ModuleName" -Recurse
}

# Synopsis: Lint Code with PSScriptAnalyzer
task Analyze BeforeAnalyze, {
    $scriptAnalyzerParams = @{
        Path = $ModulePath
        Severity = @('Error', 'Warning')
        Recurse = $true
        Verbose = $false
    }

    $saResults = Invoke-ScriptAnalyzer @scriptAnalyzerParams

    # Save Analyze Results as JSON
    $saResults | ConvertTo-Json | Set-Content (Join-Path $Artifacts "ScriptAnalysisResults.json")

    if ($saResults) {
        $saResults | Format-Table
        throw "One or more PSScriptAnalyzer errors/warnings where found."
    }
}, AfterAnalyze

# Synopsis: Test the project with Pester. Publish Test and Coverage Reports
task RunTests {
    $invokePesterParams = @{
        OutputFile =  (Join-Path $Artifacts "TestResults.xml")
        OutputFormat = 'NUnitXml'
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
        CodeCoverage = (Get-ChildItem -Path "$ModulePath/*.ps1" -Exclude "*.Tests.*" -Recurse).FullName
    }

    # Publish Test Results as NUnitXml
    $testResults = Invoke-Pester @invokePesterParams;

    # Save Test Results as JSON
    $testresults | ConvertTo-Json -Depth 5 | Set-Content  (Join-Path $Artifacts "PesterResults.json")
}

# Synopsis: Throws and error if any tests do not pass for CI usage
task ConfirmTestsPassed {
    # Fail Build after reports are created, this allows CI to publish test results before failing
    [xml] $xml = Get-Content (Join-Path $Artifacts "TestResults.xml")
    $numberFails = $xml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

    # Fail Build if Coverage is under requirement
    # $json = Get-Content (Join-Path $Artifacts "PesterResults.json") | ConvertFrom-Json
    # $overallCoverage = [Math]::Floor(($json.CodeCoverage.NumberOfCommandsExecuted / $json.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    # assert($OverallCoverage -gt $PercentCompliance) ('A Code Coverage of "{0}" does not meet the build requirement of "{1}"' -f $overallCoverage, $PercentCompliance)
}

# Synopsis: Creates Archived Zip and Nuget Artifacts
task Archive BeforeArchive, {
    # $moduleInfo = @{
    #     ModuleName = $ModuleName
    #     BuildNumber = $BuildNumber
    # }

    # Publish-ArtifactZip @moduleInfo

    # $nuspecInfo = @{
    #     packageName = $ModuleName
    #     author =  $Settings.Author
    #     owners = $Settings.Owners
    #     licenseUrl = $Settings.LicenseUrl
    #     projectUrl = $Settings.ProjectUrl
    #     packageDescription = $Settings.PackageDescription
    #     tags = $Settings.Tags
    #     destinationPath = $Artifacts
    #     BuildNumber = $BuildNumber
    # }

    # Publish-NugetPackage @nuspecInfo
}, AfterArchive

# Synopsis: Publish to SMB File Share
task Publish BeforePublish, {
    # $moduleInfo = @{
    #     RepoName = $Settings.SMBRepoName
    #     RepoPath = $Settings.SMBRepoPath
    #     ModuleName = $ModuleName
    #     ModulePath = "$ModulePath\$ModuleName.psd1"
    #     BuildNumber = $BuildNumber
    # }

    # Publish-SMBModule @moduleInfo -Verbose
}, AfterPublish
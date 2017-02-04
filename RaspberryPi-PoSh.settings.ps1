###############################################################################
# Customize these properties and tasks
###############################################################################
param(
    $Artifacts = './artifacts',
    $ModuleName = 'RaspberryPi-PoSh',
    $ModulePath = './RaspberryPi-PoSh',
    $ModulesPath = '/usr/local/share/powershell/Modules/',
    $BuildNumber = $env:BUILD_NUMBER,
    $PercentCompliance  = '60'
)

###############################################################################
# Static settings -- no reason to include these in the param block
###############################################################################
$Settings = @{
    SMBRepoName = 'DSCGallery'
    SMBRepoPath = '\\Server01\Repo'

    Author =  "Juni Inacio"
    Owners = "Juni Inacio"
    LicenseUrl = 'https://github.com/juniinacio/RaspberryPi-PoSh/blob/master/LICENSE'
    ProjectUrl = "https://github.com/juniinacio/RaspberryPi-PoSh/"
    PackageDescription = "PowerShell v6 module for provisioning Kodi on the Raspberry Pi."
    Repository = 'https://github.com/juniinacio/RaspberryPi-PoSh.git'
    Tags = ""

    # TODO: fix any redudant naming
    GitRepo = "juniinacio/RaspberryPi-PoSh"
    CIUrl = "https://jenkins:8080/job/RaspberryPi-PoSh/"
}

###############################################################################
# Before/After Hooks for the Core Task: Clean
###############################################################################

# Synopsis: Executes before the Clean task.
task BeforeClean {}

# Synopsis: Executes after the Clean task.
task AfterClean {}

###############################################################################
# Before/After Hooks for the Core Task: Analyze
###############################################################################

# Synopsis: Executes before the Analyze task.
task BeforeAnalyze {}

# Synopsis: Executes after the Analyze task.
task AfterAnalyze {}

###############################################################################
# Before/After Hooks for the Core Task: Archive
###############################################################################

# Synopsis: Executes before the Archive task.
task BeforeArchive {}

# Synopsis: Executes after the Archive task.
task AfterArchive {}

###############################################################################
# Before/After Hooks for the Core Task: Publish
###############################################################################

# Synopsis: Executes before the Publish task.
task BeforePublish {}

# Synopsis: Executes after the Publish task.
task AfterPublish {}

###############################################################################
# Before/After Hooks for the Core Task: Test
###############################################################################

# Synopsis: Executes before the Test Task.
task BeforeTest {}

# Synopsis: Executes after the Test Task.
task AfterTest {}
$global:sudocmd = "sudo"

#----------------------------------------------------------------------------------------------------------------------
# Constants

enum Distribution {
    LibreELEC
    OpenELEC
    OSMC
}

enum EventSeverity {
	Information
	Warning
	Verbose
	Debug
	Error
}

enum PreseedOptionType {
    PRESEED_STRING
    PRESEED_BOOL
}

#----------------------------------------------------------------------------------------------------------------------
# Classes

class Logger {
    static [void] LogMessage ([string] $Message, [string] $Severity) {
        if ($Severity -eq [EventSeverity]::Information) {
            Write-Host $Message
        } elseif ($Severity -eq [EventSeverity]::Warning) {
            Write-Warning $Message
        } elseif ($Severity -eq [EventSeverity]::Verbose) {
            Write-Verbose $Message
        } elseif ($Severity -eq [EventSeverity]::Debug) {
            Write-Debug $Message
        } else {
            Write-Error $Message
        }
    }
}

class Device {
    [string] $Name
    [string] $FSType
    [string] $Size
    [string] $Mountpoint
    [string] $Type
    [string] $Label
    [string] $Hotplug
    
    [System.Collections.ArrayList] $Partitions
    
    [Device] $Parent

    Device ([string] $Name, [string] $FSType, [string] $Size, [string] $Mountpoint, [string] $Type, [string] $Label, [string] $Hotplug) {
        $this.Name = $Name
        $this.FSType = $FSType
        $this.Size = $Size
        $this.Mountpoint = $Mountpoint
        $this.Type = $Type
        $this.Label = $Label
        $this.Hotplug = $Hotplug
        
        $this.Parent = $null
        
        $this.Partitions = [System.Collections.ArrayList]::New()
    }

    [Device] GetParent () {
        return $this.Parent
    }

    [void] SetParent ([Device] $Parent) {
        $this.Parent = $Parent
    }

    [Device] GetPartition ([int] $Index) {
        if ($Index -lt $this.Partitions.Count -and $Index -ge 0) {
            return $this.Partitions.Item($Index)
        } else {
            return $null
        }
    }

    [void] SetPartition ([Device] $Partition) {
        $this.Partitions.Add($Partition)
    }

    [System.Collections.ArrayList] GetPartitions () {
        return $this.Partitions
    }

    [string] GetPath () {
        return $('/dev/{0}' -f $this.Name)
    }

    [bool] Umount () {
        return ([string]::IsNullOrEmpty($this.Mountpoint) -eq $false)
    }

    [string] ToString () {
        return $this.GetPath()
    }
}

class DeviceService {

    static [System.Collections.ArrayList] GetDevices ([bool] $Force = $false) {
        $arrayList = [System.Collections.ArrayList]::New()
        
        if ([Utility]::OSVersion() -like 'jessie*' -or [Utility]::OSVersion() -like 'CentOS*7*') {
            $output = ExecCmd -Command 'lsblk' -ArgumentsList '-a', '-P', '-b', '-o', 'name,fstype,size,mountpoint,type,label,rm'
        } else {
            $output = ExecCmd -Command 'lsblk' -ArgumentsList '-a', '-P', '-b', '-o', 'name,fstype,size,mountpoint,type,label,hotplug'
        }
        
        [Logger]::LogMessage($output, [EventSeverity]::Debug)

        $hashtables = $output.Split("`n") | ForEach-Object {(($_ -replace '(?<=")\s', "`n") -replace '"', '') -replace 'rm=', 'hotplug=' | ConvertFrom-StringData}

        $devices = $hashtables | Where-Object {$_.name -match "\A((?=[^0-9]+\z)|(?=(mmcblk|loop)\d\z))"}

        foreach ($dev in $devices) {
            if (($dev.hotplug -eq 0) -and ($Force -eq $false) -and ($dev.name -notmatch 'loop\d\z')) {
                continue;
            }

            $device = [Device]::new($dev.name, $dev.fstype, $dev.size, $dev.mountpoint, $dev.type, $dev.label, $dev.hotplug)

            $partitions = $hashtables | Where-Object {$_.name -match ("\A{0}p?\d\z" -f $dev.name)}

            foreach ($part in $partitions) {
                $partition = [Device]::new($part.name, $part.fstype, $part.size, $part.mountpoint, $part.type, $part.label, $part.hotplug)
                
                $partition.SetParent($device)
                
                $device.SetPartition($partition)
            }

            $arrayList.Add($device)
        }

        return $arrayList
    }

    static [Device] GetDevice ([string] $Path) {
        return $([DeviceService]::GetDevices($true) | Where-Object {$_.GetPath() -eq $Path})
    }
}

class Utility {

    static [void] Umount ([Device] $Device) {
        if ($Device.Type -eq 'disk') {
            foreach ($p in $Device.GetPartitions()) {
                [Utility]::Umount($p)
            }
        } else {
            if ($Device.Umount()) {
                ExecCmd -Command 'umount' -ArgumentsList $($Device.GetPath())
            }
        }
    }

    static [void] Mount ([Device] $Device, [string] $Destination) {
        if ($Device.Type -ne 'disk') {
            if (-not $Device.Umount()) {
                if ($Device.Type -eq 'loop') {
                    ExecCmd -Command 'mount' -ArgumentsList $Device.GetPath(), $Destination
                } elseif ($Device.Type -eq 'part') {
                    if ($Device.FSType -eq 'vfat') {
                        ExecCmd -Command 'mount' -ArgumentsList '-t', $Device.FSType, '-o', 'umask=000', $Device.GetPath(), $Destination
                    } else {
                        ExecCmd -Command 'mount' -ArgumentsList '-t', $Device.FSType, $Device.GetPath(), $Destination
                    }
                } else {

                }
            }
        }
    }

    static [void] Sync () {
        ExecCmd -Command 'sync'
    }

    static [string] Mimetype ([string] $FilePath) {
        $output = [string]::Empty

        if (Test-Path -Path $FilePath -PathType Leaf) {
            $output = ExecCmd -Command 'file' -ArgumentsList '--mime-type', '-b', $FilePath
        }

        return $output.Trim()
    }

    static [string] Which ([string] $Command) {
        $output = [string]::Empty

        $output = ExecCmd -Command 'which' -ArgumentsList $Command

        return $output.Trim()
    }

    static [void] DD([string] $If, [string]$Of, [long] $Bs, [long] $Count) {
        ExecCmd -Command 'dd' -ArgumentsList "if=$If", "of=$Of", "bs=$Bs", "count=$Count", 'status=none'
    }

    static [string] OSVersion() {
        $output = [string]::Empty

        if (Test-Path -Path '/etc/debian_version') {
            $output = Get-Content -Path '/etc/debian_version'
        } elseif (Test-Path -Path '/etc/redhat-release') {
            $output = Get-Content -Path '/etc/redhat-release'
        }

        return $output
    }
}

class Parted {

    static [void] MKLabel ([Device] $Device, [string] $Label) {
        ExecCmd -Command 'parted' -ArgumentsList '-s', $Device.GetPath(), 'mklabel', $Label
    }

    static [void] MKPart ([Device] $Device, [string] $PartType, [string] $Unit, [string] $FsType, [string] $Start, [string] $End) {
        ExecCmd -Command 'parted' -ArgumentsList '-s', $Device.GetPath(), 'unit', $Unit, 'mkpart', $PartType, $FsType, '--', $Start, $End
    }

    static [bool] Aligncheck ([Device] $Device, [string] $Type, [uint32] $Partition) {
        $output = ExecCmd -Command 'parted' -ArgumentsList $Device.GetPath(), 'align-check', $Type, $Partition
        [Logger]::LogMessage("Output: $output", [EventSeverity]::Debug)
        return ($output -imatch "\d+ aligned")
    }

    static [void] Set ([Device] $Device, [Uint32] $Number, [string] $Flag, [string] $State) {
        ExecCmd -Command 'parted' -ArgumentsList '-s', $Device.GetPath(), 'set', $Number, $Flag, $State
    }
}

class Partprobe {
    
    static [void] Probe ([Device] $Device) {
        if ($Device.Type -eq 'part') {
            ExecCmd -Command 'partprobe' -ArgumentsList $Device.Parent.GetPath()
        } else {
            ExecCmd -Command 'partprobe' -ArgumentsList $Device.GetPath()
        }
    }
}

class Mkfs {

    static [void] VFat ([Device] $Device, [string] $Label, [Uint32] $Size) {
        ExecCmd -Command 'mkfs.vfat' -ArgumentsList $Device.GetPath(), '-I', '-n', $Label, '-F', $Size
    }

    static [void] Ext4 ([Device] $Device, [string] $Label) {
        ExecCmd -Command 'mkfs.ext4' -ArgumentsList $Device.GetPath(), '-L', $Label, '-F', '-q'
    }
    
}

class Tar {

    static [void] Extract ([string] $FilePath, [string] $Destination) {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        if (-not (Test-Path -Path $Destination -PathType Container)) {
            throw "Cannot find path '$Destination' because it does not exist."
        }

        ExecCmd -Command 'tar' -ArgumentsList '-xf', $FilePath, '-C', $Destination, '--no-same-owner'
    }

    static [void] Create ([string] $Source, [string] $Destination) {
        if (-not (Test-Path -Path $Source -PathType Container)) {
            throw "Cannot find path '$Source' because it does not exist."
        }

        try {
            Push-Location
            Set-Location -Path $Source
            ExecCmd -Command 'tar' -ArgumentsList '-cf', $Destination, '.'
        } catch {
            throw $_
        } finally {
            Pop-Location
        }
    }

    static [void] CreateEx ([string] $Source, [string] $Destination, [string] $FilePath) {
        if (-not (Test-Path -Path $Source -PathType Container)) {
            throw "Cannot find path '$Source' because it does not exist."
        }

        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        try {
            Push-Location
            Set-Location -Path $Source
            ExecCmd -Command 'tar' -ArgumentsList '-cf', $Destination, '-X', $FilePath, '.'
        } catch {
            throw $_
        } finally {
            Pop-Location
        }
    }

    static [String[]] TarInfo ([string] $FilePath) {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        $output = ExecCmd -Command 'tar' -ArgumentsList '-t', '-f', $FilePath

        return @($output -split '\n')
    }
}

class Md5sum {
    static [void] Check([string] $Path) {
        try {
            $parent = Split-Path -Path $Path -Parent

            if (-not [string]::IsNullOrEmpty($parent)) {
                Push-Location
                Set-Location -Path $parent
            }

            ExecCmd -Command 'md5sum' -ArgumentsList '-c', $(Split-Path -Path $Path -Leaf)
        } catch {
            throw $_
        } finally {
            if (-not [string]::IsNullOrEmpty($parent)) {
                Pop-Location
            }
        }
    }
}

class Gzip {

    static [void] Extract ([string] $FilePath) {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        ExecCmd -Command 'gzip' -ArgumentsList '-d', $FilePath
    }
}

class Losetup {

    static [string] Lookup () {
        $output = ExecCmd -Command 'losetup' -ArgumentsList '-f'

        return $output.Trim()
    }

    static [void] Attach ([Device] $Device, [string] $FilePath) {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        ExecCmd -Command 'losetup' -ArgumentsList $Device.GetPath(), $FilePath
    }

    static [void] Detach ([Device] $Device) {
        ExecCmd -Command 'losetup' -ArgumentsList '-d', $Device.GetPath()
    }
}

# class dmsetup {

#     static [void] RemoveAll () {
#         ExecCmd -Command 'dmsetup' -ArgumentsList 'remove_all' -UseSudo
#     }
# }

# class kpartx {

#     static [void] AddPartitionDevMappings ([string] $DevicePath) {
#         ExecCmd -Command 'kpartx' -ArgumentsList '-a', $DevicePath -UseSudo
#     }
# }

class Unzip {

    static [void] Extract ([string] $FilePath, [string] $Destination) {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        if (-not (Test-Path -Path $Destination -PathType Container)) {
            throw "Cannot find path '$Destination' because it does not exist."
        }

        ExecCmd -Command 'unzip' -ArgumentsList '-oq', $FilePath, '-d', $Destination
    }

    static [String[]] ZipInfo ([string] $FilePath) {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            throw "Cannot find path '$FilePath' because it does not exist."
        }

        $output = ExecCmd -Command 'unzip' -ArgumentsList '-Z', '-1', $FilePath

        return @($output -split '\n')
    }
}

# https://github.com/osmc/osmc/blob/master/installer/host/qt_host_installer/preseeder.cpp

class PreseedFile {

    [System.Collections.ArrayList] $Content

    [string] $Path

    PreseedFile ([string] $Path) {
        if (-not (Test-Path -Path $Path -PathType Container)) {
            throw "Cannot find path '$Path' because it does not exist."
        }

        $this.Path = Join-Path -Path $Path -ChildPath 'preseed.cfg'
        $this.Content = [System.Collections.ArrayList]::New()
    }

    [void] SetNetworkSetting ([string] $Key, [int] $Type, [string] $Value) {
        $this.WriteOption('network', $Key, $Type, $Value)
    }

    [void] SetTargetSetting ([string] $Key, [int] $Type, [string] $Value) {
        $this.WriteOption('target', $Key, $Type, $Value)
    }

    [void] Save () {
        Set-Content -Path $this.Path -Value $this.Content -Force
    }

    hidden [void] WriteOption ([string] $Section, [string] $OptionKey, [int] $OptionType, [string] $OptionValue) {
        $line = [string]::Empty

        switch ([enum]::Parse([PreseedOptionType], $OptionType)) {
            PRESEED_STRING {
                $line = "d-i {0}/{1} {2} {3}" -f $Section, $OptionKey, 'string', $OptionValue
            }

            PRESEED_BOOL {
                $line = "d-i {0}/{1} {2} {3}" -f $Section, $OptionKey, 'boolean', $OptionValue
            }
        }

        $this.Content.Add($line)
    }
}

class ConfigFile {

    [System.Collections.ArrayList] $Content

    [string] $Path

    ConfigFile ([string] $Path) {
        if (-not (Test-Path -Path $Path -PathType Container)) {
            throw "Cannot find path '$Path' because it does not exist."
        }

        $this.Content = [System.Collections.ArrayList]::New()

        $this.Path = Join-Path -Path $Path -ChildPath 'config.txt'
        if (Test-Path -Path $this.Path -PathType Leaf) {
            Get-Content -Path $this.Path | ForEach-Object { $this.Content.Add($_) }
        }
    }

    [void] SetCustomSettings ([Hashtable] $Hashtable) {
        $lines = [System.Collections.ArrayList]::New()

        foreach ($line in $this.Content) {
            foreach ($key in $Hashtable.keys) {
                $line = $line -replace $('^[\s#]*{0}\s*=\s*(?<value>[a-zA-Z0-9_]+)\s*$' -f $key), $(' {0}={1}' -f $key, $Hashtable.Item($Key)) 
            }
            $lines.Add($line)
        }

        foreach ($key in $Hashtable.keys) {
            $match = $false
            
            foreach ($line in $lines) {
                if ($line -imatch ('^\s{0}={1}\s*$' -f $key, $Hashtable.Item($Key))) {
                    $match = $true
                }
            }

            if (-not $match) {
                $lines.Add($(' {0}={1}' -f $key, $Hashtable.Item($key)))
            }
        }

        $this.Content = $lines
    }

    [void] Save () {
        Set-Content -Path $this.Path -Value $this.Content -Force
    }
}

#----------------------------------------------------------------------------------------------------------------------
# Functions

function ExecCmd {
    [CmdletBinding()]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('Cmd')]
        [string]
        $Command,
        
        # Param2 help description
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ArgumentsList,

        # Param3 help description
        [Parameter(Mandatory = $false, Position = 2)]
        [Switch]
        $UseSudo
    )
    
    $sudocmd = $global:sudocmd

    if ($UseSudo.IsPresent) {
        [Logger]::LogMessage("Running: $sudocmd $Command $ArgumentsList", [EventSeverity]::Verbose)
        $output = & $sudocmd $Command @ArgumentsList
    } else {
        [Logger]::LogMessage("Running: $Command $ArgumentsList", [EventSeverity]::Verbose)
        $output = & $Command @ArgumentsList
    }

    if ($LastExitCode -ne 0) {
        throw $output
    } else {
        [Logger]::LogMessage("LastExitCode: $LastExitCode", [EventSeverity]::Verbose)
    }

    $output
}

#----------------------------------------------------------------------------------------------------------------------
# Dot source any related scripts and functions in the same directory as this module

$Paths = @(
    'Functions'
)

foreach ($p in $Paths) {
    "$(Split-Path -Path $MyInvocation.MyCommand.Path)\$p\*.ps1" | Resolve-Path | ForEach-Object {
        if ($_.ProviderPath -notlike '*_TEMPLATE*') {
            [Logger]::LogMessage("Including: $($_.ProviderPath)", [EventSeverity]::Verbose)
            . $_.ProviderPath 
        }
    }
}

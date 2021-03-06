<#
.SYNOPSIS
    Creates a backup of the Kodi installation on the Raspberry Pi.
.DESCRIPTION
    This cmdlet Creates a backup of the Kodi installation on the Raspberry Pi. Use this cmdlet together with the Install-LibreELEC, Install-OpenELEC or Install-OSMC cmdlets to
    install or restore your Raspberry Pi.
.EXAMPLE
    PS /> Backup-Raspberry -SD '/dev/mmcblk0'

    This example shows how to make a backup of your Kodi installation when installed to SD.
.EXAMPLE
    PS /> Backup-Raspberry -USB '/dev/sdc' -ExcludeFilePath '/home/ubuntu/Documents/ExcludeFile.txt'

    This example shows how to make a backup of your Kodi installation when installed to USB. For more information about the -ExcludeFilePath parameter see tar -X command.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER USBDevicePath
    Path to the USB device, e.g. /dev/sdc.
.PARAMETER FilePath
    Path to the backup file.
.PARAMETER ExcludeFilePath
    Path to the exclude file. For more information about the -ExcludeFilePath parameter see tar -X command.
#>
function Backup-Raspberry {
    [CmdletBinding()]
    Param (
        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName='SD')]
        [ValidateNotNullOrEmpty()]
        [Alias('SDDevice', 'SD')]
        [string] 
        $SDDevicePath,

        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName='USB')]
        [ValidateNotNullOrEmpty()]
        [Alias('USBDevice', 'USB')]
        [string] 
        $USBDevicePath,
        
        [Parameter(Mandatory = $false, ParameterSetName='SD')]
        [Parameter(Mandatory = $false, ParameterSetName='USB')]
        [Alias('Path')]
        [string]
        $FilePath,

        [Parameter(Mandatory = $false, ParameterSetName='SD')]
        [Parameter(Mandatory = $false, ParameterSetName='USB')]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf
        })]
        [Alias('ExcludeFile', 'Exclude')]
        [string]
        $ExcludeFilePath
    )

    begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"
    } # begin

    process {
        try {
            [string]$pb = ($PSBoundParameters | Format-Table -AutoSize | Out-String).TrimEnd()
            Write-Verbose "[PROCESS] PSBoundparameters: `n$($pb.split("`n").Foreach({"$("`t"*2)$_"}) | Out-String) `n" 
            
            if (-not $PSBoundParameters.ContainsKey('FilePath')) {
                $FilePath = Join-Path -Path $Env:HOME -ChildPath ('Backups/Kodi-{0}.tar' -f (Get-Date -format 'yyyyMMddHHmmss'))
            }

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                $devicePath = $SDDevicePath
                $index = 1
            } else {
                $devicePath = $USBDevicePath
                $index = 0
            }

            $device = [DeviceService]::GetDevice($devicePath)
            if ($null -eq $device) {
                throw "Cannot find device '$devicePath' because it does not exist."
            }

            $parent = Split-Path -Path $FilePath -Parent
            if (-not (Test-Path -Path $parent -PathType Container)) {
                New-Item -Path $parent -ItemType Directory | Out-Null
            }

            $source = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $source -PathType Container) {
                Remove-Item -Path $source -Recurse
            }

            New-Item -Path $source -ItemType Directory | Out-Null

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            $device = [DeviceService]::GetDevice($devicePath)

            [Utility]::Mount($device.GetPartition($index), $source)

            if (-not $PSBoundParameters.ContainsKey('ExcludeFilePath')) {
                [Tar]::Create($source, $FilePath)
            } else {
                [Tar]::Create($source, $FilePath, $ExcludeFilePath)
            }

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            Remove-Item -Path $source -Recurse -Force
        } catch {
            Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
            Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
            Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"
            
            $PSCmdlet.ThrowTerminatingError($_)
        } # try
    } # process

    end {
        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
    } # end
}
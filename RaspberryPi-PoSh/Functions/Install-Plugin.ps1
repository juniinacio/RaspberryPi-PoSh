Set-StrictMode -Version Latest
Set-PSDebug -Strict

<#
.SYNOPSIS
    Installs Kodi addons.
.DESCRIPTION
    This cmdlet can be use to install or more addons into an existing Raspberry Pi Kodi installation.

    This cmdlet expects the addons to be in a zipped (.zip) format, also the cmdlet does a basic validation of the addons structure.
.EXAMPLE
    PS /> Install-Plugin -SDDevicePath '/dev/mmcblk0' -Path '/home/ubuntu/Downloads/plugin.video.youtube.zip'

    This example shows how to install a Kodi plugin to SD.
.EXAMPLE
    PS /> Install-Plugin -USBDevicePath '/dev/sdc' -Path '/home/ubuntu/Downloads/plugin.video.youtube.zip'

    This example shows how to install a Kodi plugin to USB.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER USBDevicePath
    Path to the USB device, e.g. /dev/sdc.
.PARAMETER FilePath
    Path to the addon file, e.g /home/ubuntu/Downloads/plugin.video.youtube.zip.
#>
function Install-Plugin {
    [CmdletBinding()]
    Param (
        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName='SD')]
        [ValidateNotNullOrEmpty()]
        [Alias('SD')]
        [string]
        $SDDevicePath,

        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName='USB')]
        [ValidateNotNullOrEmpty()]
        [Alias('USB')]
        [string]
        $USBDevicePath,

        [Parameter(Mandatory = $false, ParameterSetName='SD', ValueFromPipeline = $true)]
        [Parameter(Mandatory = $false, ParameterSetName='USB', ValueFromPipeline = $true)]
        [Alias('Path')]
        [string[]]
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
        try {
            Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

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

            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            $destination = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $destination -PathType Container) {
                Remove-Item -Path $destination -Recurse
            }

            New-Item -Path $destination -ItemType Directory | Out-Null

            $device = [DeviceService]::GetDevice($devicePath)

            [Utility]::Mount($device.GetPartition($index), $destination)

            if (Test-Path -Path "$destination/.kodi/addons" -PathType Container) {
                $addonPath = ".kodi/addons"
            } elseif (Test-Path -Path "$destination/home/osmc/.kodi/addons" -PathType Container) {
                $addonPath = "home/osmc/.kodi/addons"
            } else {
                throw "Cannot determine OS on device '$devicePath', aborting operation."
            }

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            Remove-Item -Path $destination -Recurse -Force

            $plugins = [System.Collections.ArrayList]::New()
        } catch {
            Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
            Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
            Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"

            $PSCmdlet.ThrowTerminatingError($_)
        } # try
    } # begin

    process {
        try {
            [string]$pb = ($PSBoundParameters | Format-Table -AutoSize | Out-String).TrimEnd()
            Write-Verbose "[PROCESS] PSBoundparameters: `n$($pb.split("`n").Foreach({"$("`t"*2)$_"}) | Out-String) `n"

            foreach ($path in $FilePath) {
                try {
                    # if (
                    #                 ([Utility]::Mimetype($path) -eq 'application/zip') `
                    #         -and    (([Unzip]::ZipInfo($FilePath) | Where-Object { $_ -imatch '^[^\/]+\/addon\.xml$' }) -ne $null)
                    # ) {
                        $plugins.add($path)
                    # } else {
                    #     throw "$path is not a valid addon."
                    # }
                } catch {
                    Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
                    Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
                    Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"

                    $PSCmdlet.WriteError($_)
                } # try
            } # foreach ($path in $FilePath) {
        } catch {
            Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
            Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
            Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"

            $PSCmdlet.ThrowTerminatingError($_)
        } # try
    } # process

    end {
        try {
            Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"

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

            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            $destination = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $destination -PathType Container) {
                Remove-Item -Path $destination -Recurse
            }

            New-Item -Path $destination -ItemType Directory | Out-Null

            $device = [DeviceService]::GetDevice($devicePath)

            [Utility]::Mount($device.GetPartition($index), $destination)

            $addonPath = "$destination/$addonPath"

            foreach ($plugin in $plugins) {
                try {
                    [Unzip]::Extract($plugin, $addonPath)
                } catch {
                    Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
                    Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
                    Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"

                    $PSCmdlet.WriteError($_)
                } # try
            } # foreach ($path in $FilePath) {

            [Utility]::Sync()

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            Remove-Item -Path $destination -Recurse -Force
        } catch {
            Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
            Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
            Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"

            $PSCmdlet.ThrowTerminatingError($_)
        } # try
    } # end
}
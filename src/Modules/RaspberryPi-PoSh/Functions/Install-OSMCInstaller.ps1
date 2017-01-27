<#
.SYNOPSIS
    Installs OSMC installer.
.DESCRIPTION
    This cmdlet installs the OSMC installer the Raspberry Pi. Installing OSMC using this cmdlet has the same affect as using the Official OSMC installer.
    
    The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp*_*.img.gz).

    The cmdlet can install all Raspberry Pi versions.

    OSMC can be downloaded from one of the following locations:
    http://download.osmc.tv/
    http://download.osmc.tv/installers/diskimages/ (direct link)

.EXAMPLE
    PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'

    This example shows how to do a typical OSMC install.
.EXAMPLE
    PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'

    This example shows how to do an install to USB.
.EXAMPLE
    PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'MyNetwork'

    This example shows how to install to SD and configure WiFi.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER USB
    Specifies to install to USB.
.PARAMETER FilePath
    Path to the OSMC image file.
.PARAMETER WLAN
    Specifies that wireless should be used.
.PARAMETER KeyType
    Specifies the encryption type of the wireless network.
.PARAMETER Key
    Specifies the password of the wireless network.
.PARAMETER SSID
    Specifies the SSID of the wireless network.
.NOTES
    Overclocking the Raspberry Pi? See here below some usefull resources.
    https://haydenjames.io/raspberry-pi-2-overclock/
    https://haydenjames.io/raspberry-pi-3-overclock/
#>
function Install-OSMCInstaller {
    [CmdletBinding(
        DefaultParameterSetName = 'eth'
    )]
    param (
        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName = 'eth')]
        [Parameter(Mandatory = $true, ParameterSetName = 'wlan')]
        [ValidateNotNullOrEmpty()]
        [Alias('SD')]
        [string]
        $SDDevicePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'eth')]
        [Parameter(Mandatory = $false, ParameterSetName = 'wlan')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $USB,

        [Parameter(Mandatory = $true, ParameterSetName = 'eth')]
        [Parameter(Mandatory = $true, ParameterSetName = 'wlan')]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf
        })]
        [Alias('Path')]
        [string]
        $FilePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'wlan')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $WLAN,

        [Parameter(Mandatory = $false, ParameterSetName = 'wlan')]
        [ValidateSet('Open_Network', 'WPA/WPA2_PSK', 'WEP')]
        [string]
        $KeyType = 'WPA/WPA2_PSK',

        [Parameter(Mandatory = $false, ParameterSetName = 'wlan')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key = '',

        [Parameter(Mandatory = $true, ParameterSetName = 'wlan')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SSID
    )
    
    begin {
        try {
            Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD -eq $null) {
                throw "Cannot find device '$SDDevicePath' because it does not exist."
            }

            [Utility]::Umount($SD)

            [DD]::Copy('/dev/zero', $SD, 512, 1)

            [Parted]::MKLabel($SD, 'msdos')

            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)

            if (-not ([Parted]::Aligncheck($SD, 'opt', 1))) {
                Write-Error "Device '$($SD.GetPartition(0))' is not aligned."
            }

            [Parted]::Set($SD, 1, 'boot', 'on')

            [Partprobe]::Probe($SD)
 
            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Mkfs]::VFat($SD.GetPartition(0), 'SYSTEM', 32)

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }
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
            
            $source = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $source -PathType Container) {
                Remove-Item -Path $source -Recurse
            }

            New-Item -Path $source -ItemType Directory | Out-Null

            $destination = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $destination -PathType Container) {
                Remove-Item -Path $destination -Recurse
            }

            New-Item -Path $destination -ItemType Directory | Out-Null

            $build = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $build -PathType Container) {
                Remove-Item -Path $build -Recurse
            }

            New-Item -Path $build -ItemType Directory | Out-Null

            $file = Get-Item -Path $FilePath

            $file = Copy-Item -Path $file -Destination $build -PassThru

            [Gzip]::Extract($file.FullName)

            $file = Get-Item -Path (Join-Path -Path $build -ChildPath $file.Basename)

            $loopPath = [Losetup]::Lookup()

            $loop = [DeviceService]::GetDevice($loopPath)

            [Losetup]::Attach($loop, $file.FullName)

            [Partprobe]::Probe($loop)

            $loop = [DeviceService]::GetDevice($loopPath)

            [Utility]::Mount($loop.GetPartition(0), $source)

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SD.GetPartition(0), $destination)

            Copy-Item -Path "$source/*" -Destination "$destination/" -Recurse

            [Utility]::Sync()

            $loop = [DeviceService]::GetDevice($loopPath)
            if ($loop.GetPartition(0).Umount()) {
                [Utility]::Umount($loop.GetPartition(0))
            }

            [Losetup]::Detach($loop)

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            Remove-Item -Path $source -Recurse -Force
            Remove-Item -Path $build -Recurse -Force
            Remove-Item -Path $destination -Recurse -Force
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
            
            $destination = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $destination -PathType Container) {
                Remove-Item -Path $destination -Recurse
            }

            New-Item -Path $destination -ItemType Directory | Out-Null

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            [Utility]::Mount($SD.GetPartition(0), $destination)

            $preseedFile = [PreseedFile]::New($destination)

            if (-not $USB.IsPresent) {
                $preseedFile.SetTargetSetting('storage', [PreseedOptionType]::PRESEED_STRING, 'sd')
            } else {
                $preseedFile.SetTargetSetting('storage', [PreseedOptionType]::PRESEED_STRING, 'usb')
            }

            if ($PSCmdlet.ParameterSetName -eq 'eth') {
                $preseedFile.SetNetworkSetting('interface', [PreseedOptionType]::PRESEED_STRING, 'eth')
            } else {
                $preseedFile.SetNetworkSetting('interface', [PreseedOptionType]::PRESEED_STRING, 'wlan')
                $preseedFile.SetNetworkSetting('ssid', [PreseedOptionType]::PRESEED_STRING, $SSID)
                $preseedFile.SetNetworkSetting('wlan_key', [PreseedOptionType]::PRESEED_STRING, $Key)

                if ($KeyType -eq 'Open_Network') {
                    $preseedFile.SetNetworkSetting('wlan_keytype', [PreseedOptionType]::PRESEED_STRING, 0)
                } elseif ($KeyType -eq 'WPA/WPA2_PSK') {
                    $preseedFile.SetNetworkSetting('wlan_keytype', [PreseedOptionType]::PRESEED_STRING, 1)
                } else {
                    $preseedFile.SetNetworkSetting('wlan_keytype', [PreseedOptionType]::PRESEED_STRING, 2)
                }
            }
            
            $preseedFile.SetNetworkSetting('auto', [PreseedOptionType]::PRESEED_BOOL, 'true')

            $preseedFile.Save()

            [Utility]::Sync()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
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
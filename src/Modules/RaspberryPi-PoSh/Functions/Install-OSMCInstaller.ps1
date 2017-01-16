<#
.SYNOPSIS
    Installs OSMC installer.
.DESCRIPTION
    This cmdlet installs the OSMC installer the Raspberry Pi. Installing OSMC using this cmdlet has the same affect as using the Official OSMC installer.
    
    The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp2_20161128.img.gz).

    The cmdlet can do installs for all Raspberry Pi versions.

    OSMC can be downloaded from one of the following locations:
    http://download.osmc.tv/
    http://download.osmc.tv/installers/diskimages/ (direct link)

.EXAMPLE
    PS /> Install-OSMCInstaller -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'

    This example shows how to do a typical OSMC install.
.EXAMPLE
    PS /> Install-OSMCInstaller -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'

    This example shows how to do an install to USB.
.EXAMPLE
    PS /> Install-OSMCInstaller -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'MyNetwork'

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
.LINK
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
        [Alias('SDDevice', 'SD')]
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

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice -eq $null) {
                throw "Cannot find device '$SDDevicePath' because it does not exist."
            }

            [Utility]::Umount($SDDevice)

            [Parted]::MKLabel($SDDevice, 'msdos')

            [Parted]::MKPart($SDDevice, 'primary', 'cyl', 'fat32', 0, 65)

            if (-not ([Parted]::Aligncheck($SDDevice, 'opt', 1))) {
                Write-Error "Device '$($SDDevice.GetPartition(0))' is not aligned."
            }

            [Parted]::Set($SDDevice, 1, 'boot', 'on')

            [Partprobe]::Probe($SDDevice)
 
            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            [Mkfs]::VFat($SDDevice.GetPartition(0), 'SYSTEM', 32)

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
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

            [Losetup]::Attach($loop.GetPath(), $file.FullName)

            [Partprobe]::Probe($loop)

            $loop = [DeviceService]::GetDevice($loopPath)

            [Utility]::Mount($loop.GetPartition(0), $source)

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
            }

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SDDevice.GetPartition(0), $destination)

            Copy-Item -Path "$source/*" -Destination "$destination/" -Recurse

            [Utility]::Sync()

            $loop = [DeviceService]::GetDevice($loopPath)
            if ($loop.GetPartition(0).Umount()) {
                [Utility]::Umount($loop.GetPartition(0))
            }

            [Losetup]::Detach($loop.GetPath())

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
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

            $destination = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $destination -PathType Container) {
                Remove-Item -Path $destination -Recurse
            }

            New-Item -Path $destination -ItemType Directory | Out-Null

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
            }

            [Utility]::Mount($SDDevice.GetPartition(0), $destination)

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
                    $preseedFile.SetNetworkSetting('wlan_KeyType', [PreseedOptionType]::PRESEED_STRING, 0)
                } elseif ($KeyType -eq 'WPA/WPA2_PSK') {
                    $preseedFile.SetNetworkSetting('wlan_KeyType', [PreseedOptionType]::PRESEED_STRING, 1)
                } else {
                    $preseedFile.SetNetworkSetting('wlan_KeyType', [PreseedOptionType]::PRESEED_STRING, 2)
                }
            }
            
            $preseedFile.SetNetworkSetting('auto', [PreseedOptionType]::PRESEED_BOOL, 'true')

            $preseedFile.Save()

            [Utility]::Sync()

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
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
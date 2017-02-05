Set-StrictMode -Version Latest
Set-PSDebug -Strict

<#
.SYNOPSIS
    Installs and restores OSMC.
.DESCRIPTION
    This cmdlet installs and restores OSMC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Using this cmdlet u will be able to do both a SD or USB install of OSMC.

    The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp*_*.img.gz).

    The cmdlet can install all Raspberry Pi versions.

    OSMC can be downloaded from one of the following locations:
    http://download.osmc.tv/
    http://download.osmc.tv/installers/diskimages/ (direct link)
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'

    This example shows how to do a typical install of OSMC.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}

    This example shows how to do an install to USB of OSMC.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}

    This example shows how to do a typical install of OSMC and specifying some custom settings.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Kodi/Backups/OSMC-20161223084639.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}

    This example shows how to do advanced install of OSMC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/loop0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Backups/OSMC-20161223084639.tar'

    This example shows how to install OSMC using a loopback device. Notice that before executing the cmdlet, you will have to manually attach the disk image to the loopback device and afterwards execute the cmdlets indicating the loopback device you have attached the disk image. In this example we have attached the disk image to /dev/loop0.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER FilePath
    Path to the OSMC image file. Please keep the original name as the cmdlet depends on it.
.PARAMETER CustomSettings
    Hashtable containing custom settings, these settings will be set as settings in the config.txt file.
.PARAMETER RestoreFilePath
    Path to the backup file.
.PARAMETER USBDevicePath
    Path to the USB device, e.g. /dev/sdc.
.NOTES
    Overclocking the Raspberry Pi? See here below some usefull resources.
    https://haydenjames.io/raspberry-pi-2-overclock/
    https://haydenjames.io/raspberry-pi-3-overclock/
#>
function Install-OSMC {
    [CmdletBinding(
        DefaultParameterSetName = 'SD'
    )]
    param (
        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName = 'SD')]
        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [Alias('SD')]
        [string]
        $SDDevicePath,

        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [Alias('USB')]
        [string]
        $USBDevicePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'SD')]
        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf
        })]
        [Alias('Path')]
        [string]
        $FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'SD')]
        [Parameter(Mandatory = $false, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $CustomSettings,

        [Parameter(Mandatory = $false, ParameterSetName = 'SD')]
        [Parameter(Mandatory = $false, ParameterSetName = 'USB')]
        [ValidateScript({
            Test-Path -Path $_ -PathType Leaf
        })]
        [Alias('RestoreFile')]
        [string]
        $RestoreFilePath
    )

    begin {
        try {
            Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($null -eq $SD) {
                throw "Cannot find device '$SDDevicePath' because it does not exist."
            }

            if ($PSCmdlet.ParameterSetName -eq 'USB') {
                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($null -eq $USB) {
                    throw "Cannot find device '$USBDevicePath' because it does not exist."
                }

                [Utility]::Umount($USB)
            }

            [Utility]::Umount($SD)

            [DD]::Copy('/dev/zero', $SD, 512, 1)

            [Parted]::MKLabel($SD, 'msdos')

            [Parted]::MKPart($SD, 'primary', 'cyl', 'fat32', 0, 65)

            if (-not ([Parted]::Aligncheck($SD, 'opt', 1))) {
                Write-Error "Device '$($SD.GetPartition(0))' is not aligned."
            }

            [Parted]::Set($SD, 1, 'boot', 'on')

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                [Parted]::MKPart($SD, 'primary', 'cyl', 'ext2', 65, -2)

                if (-not ([Parted]::AlignCheck($SD, 'opt', 2))) {
                    Write-Error "Device '$($SD.GetPartition(1))' is not aligned."
                }
            }

            [Partprobe]::Probe($SD)

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Mkfs]::VFat($SD.GetPartition(0), 'SYSTEM', 32)

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                [Mkfs]::Ext4($SD.GetPartition(1), 'STORAGE')
            } else {
                [DD]::Copy('/dev/zero', $USB, 512, 1)

                [Parted]::MKLabel($USB, 'msdos')

                [Parted]::MKPart($USB, 'primary', 'cyl', 'ext2', 0, -2)

                if (-not ([Parted]::Aligncheck($USB, 'opt', 1))) {
                    Write-Error "Device '$($USB.GetPartition(0))' is not aligned."
                }

                [Partprobe]::Probe($USB)

                $USB = [DeviceService]::GetDevice($USBDevicePath)

                [Mkfs]::Ext4($USB.GetPartition(0), 'STORAGE')
            }

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                if ($SD.GetPartition(1).Umount()) {
                    [Utility]::Umount($SD.GetPartition(1))
                }
            } else {
                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }
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

            ############################################
            # Copy OSMC files to storage
            #

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

            $temp = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
            if (Test-Path -Path $temp -PathType Container) {
                Remove-Item -Path $temp -Recurse
            }

            New-Item -Path $temp -ItemType Directory | Out-Null

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                $devicePath = $SDDevicePath
                $index = 1
            } else {
                $devicePath = $USBDevicePath
                $index = 0
            }

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            $device = [DeviceService]::GetDevice($devicePath)

            [Utility]::Mount($device.GetPartition($index), $destination)

            $file = Get-Item -Path $FilePath

            $file = Copy-Item -Path $file -Destination $temp -PassThru

            [Gzip]::Extract($file.FullName)

            $file = Get-Item -Path (Join-Path -Path $temp -ChildPath $file.Basename)

            $loopPath = [Losetup]::Lookup()

            $loop = [DeviceService]::GetDevice($loopPath)

            [Losetup]::Associate($loop, $file.FullName)

            [Partprobe]::Probe($loop)

            $loop = [DeviceService]::GetDevice($loopPath)

            [Utility]::Mount($loop.GetPartition(0), $source)

            if (-not (Test-Path -Path (Join-Path -Path $source -ChildPath 'filesystem.tar.xz') -PathType Leaf)) {
                throw "Cannot find path '$(Join-Path -Path $source -ChildPath 'filesystem.tar.xz')' because it does not exist."
            }

            $extractScript = Join-Path -Path $PSScriptRoot -ChildPath '../Files/extract-osmc-filesystem.sh'
            if (-not (Test-Path -Path $extractScript -PathType Leaf)) {
                throw "Cannot find path '$extractScript' because it does not exist."
            }

            Write-Verbose ('Running: ''{0}'' ''{1}'' ''{2}''' -f $extractScript, $(Join-Path -Path $source -ChildPath 'filesystem.tar.xz'), $destination)

            $output = & $extractScript $(Join-Path -Path $source -ChildPath 'filesystem.tar.xz') $destination
            if ($LastExitCode -ne 0) {
                throw $output
            } else {
                Write-Verbose "LastExitCode: $LastExitCode"
            }

            [Utility]::Sync()

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            $loop = [DeviceService]::GetDevice($loopPath)
            if ($loop.GetPartition(0).Umount()) {
                [Utility]::Umount($loop.GetPartition(0))
            }

            [Losetup]::Disassociate($loop)

            Remove-Item -Path $source -Recurse -Force
            Remove-Item -Path $temp -Recurse -Force
            Remove-Item -Path $destination -Recurse -Force

            ############################################
            # Create SD
            #

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

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SD.GetPartition(0), $destination)

            if ($PSCmdlet.ParameterSetName -eq 'SD') {

                [Utility]::Mount($SD.GetPartition(1), $source)

                Copy-Item   -Path "$source/boot/*" -Destination "$destination/" -Recurse
                Remove-Item -Path "$source/boot/*" -Recurse

                [Utility]::Sync()

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(1).Umount()) {
                    [Utility]::Umount($SD.GetPartition(1))
                }

            } else {
                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }

                $USB = [DeviceService]::GetDevice($USBDevicePath)

                [Utility]::Mount($USB.GetPartition(0), $source)

                Copy-Item   -Path "$source/boot/*" -Destination "$destination/" -Recurse
                Remove-Item -Path "$source/boot/*" -Recurse

                [Utility]::Sync()

                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }
            }

            $file = Get-Item -Path $FilePath
            if ($file.Name -like '*rbp2*') {
                if ($PSCmdlet.ParameterSetName -eq 'SD') {
                    "root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp2" | Set-Content -Path "$destination/cmdline.txt" -Force
                } else {
                    "root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp2" | Set-Content -Path "$destination/cmdline.txt" -Force
                }
            } else {
                if ($PSCmdlet.ParameterSetName -eq 'SD') {
                    "root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp1" | Set-Content -Path "$destination/cmdline.txt" -Force
                } else {
                    "root=LABEL=STORAGE rootfstype=ext4 rootwait quiet osmcdev=rbp1" | Set-Content -Path "$destination/cmdline.txt" -Force
                }
            }

            if ($file.Name -like '*rbp2*') {
                Set-Content -Path "$destination/config.txt" -Force -Value @'
  gpu_mem_1024=256
  hdmi_ignore_cec_init=1
  disable_overscan=1
  start_x=1
  disable_splash=1
'@
            } else {
                Set-Content -Path "$destination/config.txt" -Force -Value @'
  arm_freq=850
  core_freq=375
  gpu_mem_256=112
  gpu_mem_512=144
  hdmi_ignore_cec_init=1
  disable_overscan=1
  start_x=1
  disable_splash=1
'@
            }

            if ($PSBoundParameters.ContainsKey('CustomSettings')) {
                $config = [Config]::new($destination)
                $config.SetCustomSettings($CustomSettings)
                $config.Save()
            }

            [Utility]::Sync()

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            Remove-Item -Path $source -Recurse -Force
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

            if ($PSBoundParameters.ContainsKey('RestoreFilePath')) {

                $destination = Join-Path -Path '/tmp' -ChildPath $('{0}' -f (New-Guid).ToString())
                if (Test-Path -Path $destination -PathType Container) {
                    Remove-Item -Path $destination -Recurse
                }

                New-Item -Path $destination -ItemType Directory | Out-Null

                if ($PSCmdlet.ParameterSetName -eq 'SD') {
                    $devicePath = $SDDevicePath
                    $index = 1
                } else {
                    $devicePath = $USBDevicePath
                    $index = 0
                }

                $device = [DeviceService]::GetDevice($devicePath)
                if ($device.GetPartition($index).Umount()) {
                    [Utility]::Umount($device.GetPartition($index))
                }

                $device = [DeviceService]::GetDevice($devicePath)

                [Utility]::Mount($device.GetPartition($index), $destination)

                $file = Get-Item -Path $RestoreFilePath

                [Tar]::Extract($file.FullName, $destination)

                New-Item -Path "$destination/walkthrough_completed" -ItemType File -Force | Out-Null

                [Utility]::Sync()

                $device = [DeviceService]::GetDevice($devicePath)
                if ($device.GetPartition($index).Umount()) {
                    [Utility]::Umount($device.GetPartition($index))
                }

                Remove-Item -Path $destination -Recurse -Force
            }
        } catch {
            Write-Verbose "ScriptStackTrace: $($_.ScriptStackTrace.ToString())"
            Write-Verbose "ScriptLineNumber: $($_.InvocationInfo.ScriptLineNumber)"
            Write-Verbose "ScriptName: $($_.InvocationInfo.ScriptName)"

            $PSCmdlet.ThrowTerminatingError($_)
        } # try
    } # end
}
<#
.SYNOPSIS
    Installs and restores OSMC.
.DESCRIPTION
    This cmdlet installs and restores OSMC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Using this cmdlet u will be able to do both a SD or USB install of OSMC.
    
    The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp2_20161128.img.gz).

    The cmdlet can do installs for all Raspberry Pi versions.

    OSMC can be downloaded from one of the following locations:
    http://download.osmc.tv/
    http://download.osmc.tv/installers/diskimages/ (direct link)

.EXAMPLE
    PS /> Install-OSMC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'

    This example shows how to do a typical install of OSMC.
.EXAMPLE
    PS /> Install-OSMC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}

    This example shows how to do an install to USB of OSMC.
.EXAMPLE
    PS /> Install-OSMC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}

    This example shows how to do a typical install of OSMC and specifying some custom settings.
.EXAMPLE
    PS /> Install-OSMC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Kodi/Backup/OpenELEC-20161214183622.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}

    This example shows how to do advanced install of OSMC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.
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
.LINK
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
        [Alias('SDDevice', 'SD')]
        [string]
        $SDDevicePath,

        [ArgumentCompleter({$wordToComplete = $args[2]; [DeviceService]::GetDevices($false) | Where-Object {$_.GetPath() -like "$wordToComplete*"} | Select-Object -ExpandProperty Path | Sort-Object})]
        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [Alias('USBDevice', 'USB')]
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

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice -eq $null) {
                throw "Cannot find device '$SDDevicePath' because it does not exist."
            }

            if ($PSCmdlet.ParameterSetName -eq 'USB') {
                $USBDevice = [DeviceService]::GetDevice($USBDevicePath)
                if ($USBDevice -eq $null) {
                    throw "Cannot find device '$USBDevicePath' because it does not exist."
                }

                [Utility]::Umount($USBDevice)
            }

            [Utility]::Umount($SDDevice)

            [Parted]::MKLabel($SDDevice, 'msdos')

            [Parted]::MKPart($SDDevice, 'primary', 'cyl', 'fat32', 0, 65)

            if (-not ([Parted]::Aligncheck($SDDevice, 'opt', 1))) {
                Write-Error "Device '$($SDDevice.GetPartition(0))' is not aligned."
            }

            [Parted]::Set($SDDevice, 1, 'boot', 'on')

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                [Parted]::MKPart($SDDevice, 'primary', 'cyl', 'ext2', 65, -2)

                if (-not ([Parted]::AlignCheck($SDDevice, 'opt', 2))) {
                    Write-Error "Device '$($SDDevice.GetPartition(1))' is not aligned."
                }
            }

            [Partprobe]::Probe($SDDevice)
 
            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            [Mkfs]::VFat($SDDevice.GetPartition(0), 'SYSTEM', 32)

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                [Mkfs]::Ext4($SDDevice.GetPartition(1), 'STORAGE')
            } else {
                [Parted]::MKLabel($USBDevice, 'msdos')

                [Parted]::MKPart($USBDevice, 'primary', 'cyl', 'ext2', 0, -2)

                if (-not ([Parted]::Aligncheck($USBDevice, 'opt', 1))) {
                    Write-Error "Device '$($USBDevice.GetPartition(0))' is not aligned."
                }

                [Partprobe]::Probe($USBDevice)

                $USBDevice = [DeviceService]::GetDevice($USBDevicePath)

                [Mkfs]::Ext4($USBDevice.GetPartition(0), 'STORAGE')
            }

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
            }

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                if ($SDDevice.GetPartition(1).Umount()) {
                    [Utility]::Umount($SDDevice.GetPartition(1))
                }
            } else {
                $USBDevice = [DeviceService]::GetDevice($USBDevicePath)
                if ($USBDevice.GetPartition(0).Umount()) {
                    [Utility]::Umount($USBDevice.GetPartition(0))
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

            ############################################
            # 1) Prepare storage device
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

            $loop = [DeviceService]::GetDevice($loopPath)
            if ($loop.GetPartition(0).Umount()) {
                [Utility]::Umount($loop.GetPartition(0))
            }

            [Losetup]::Detach($loop)

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            Remove-Item -Path $source -Recurse -Force
            Remove-Item -Path $build -Recurse -Force
            Remove-Item -Path $destination -Recurse -Force

            ############################################
            # 2) Create boot device
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

            [Utility]::Mount($device.GetPartition($index), $source)

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
            }

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SDDevice.GetPartition(0), $destination)

            Copy-Item   -Path "$source/boot/*" -Destination "$destination/" -Recurse
            Remove-Item -Path "$source/boot/*" -Recurse

            $file = Get-Item -Path $FilePath
            if ($file.Name -like '*rbp2*') {
                if ($PSCmdlet.ParameterSetName -eq 'SD') {
                    "root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet osmcdev=rbp2" | Set-Content -Path "$destination/cmdline.txt" -Force
                } else {
                    "root=/dev/sda1 rootfstype=ext4 rootwait quiet osmcdev=rbp2" | Set-Content -Path "$destination/cmdline.txt" -Force
                }
            } else {
                if ($PSCmdlet.ParameterSetName -eq 'SD') {
                    "root=/dev/mmcblk0p2 rootfstype=ext4 rootwait quiet osmcdev=rbp1" | Set-Content -Path "$destination/cmdline.txt" -Force
                } else {
                    "root=/dev/sda1 rootfstype=ext4 rootwait quiet osmcdev=rbp1" | Set-Content -Path "$destination/cmdline.txt" -Force
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
                $configFile = [ConfigFile]::new($destination)
                $configFile.SetCustomSettings($CustomSettings)
                $configFile.Save()
            }

            [Utility]::Sync()

            $device = [DeviceService]::GetDevice($devicePath)
            if ($device.GetPartition($index).Umount()) {
                [Utility]::Umount($device.GetPartition($index))
            }

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
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

                # "" | Set-Content -Path "$destination/walkthrough_completed" -Force
                New-Item -Path "$destination/walkthrough_completed" -ItemType File -Force

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
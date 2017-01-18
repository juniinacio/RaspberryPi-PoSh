<#
.SYNOPSIS
    Installs and restores OSMC.
.DESCRIPTION
    This cmdlet installs and restores OSMC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Using this cmdlet u will be able to do both a SD or USB install of OSMC.
    
    The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp2_20161128.sources.gz).

    The cmdlet can do installs for all Raspberry Pi versions.

    OSMC can be downloaded from one of the following locations:
    http://download.osmc.tv/
    http://download.osmc.tv/installers/diskimages/ (direct link)

    The cmdlet also supports installing to loop devices, to do this you have to prepare an empty image file before executing the cmdlet and pointing it to the image file using either the SDDeviceFilePath or the USBDeviceFilePath dynamic parameter. The SDDeviceFilePath or USBDeviceFilePath parameters are only available when either or both the SDDevicePath or USBDevicePath parameters are pointing to a loop back device, see the examples for more information about this functionality.

    Note that when doing image provisioning the SDDevicePath or USBDevicePath must point to a free loop device.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.sources.gz'

    This example shows how to do a typical install of OSMC.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.sources.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}

    This example shows how to do an install to USB of OSMC.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.sources.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}

    This example shows how to do a typical install of OSMC and specifying some custom settings.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.sources.gz' -RestoreFilePath '/home/ubuntu/Kodi/Backups/OSMC-20161223084639.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}

    This example shows how to do advanced install of OSMC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.
.EXAMPLE
    PS /> Install-OSMC -SDDevicePath '/dev/loop0' -SDDeviceFilePath '/home/ubuntu/Images/OSMC-4gb-SD-20170117.img' -USBDevicePath '/dev/loop1' -USBDeviceFilePath '/home/ubuntu/Images/OSMC-16gb-USB-20170117.img' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Backups/OSMC-20161223084639.tar'

    This example shows how to install OSMC to USB using loop devices.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER SDDeviceFilePath
    Path to the SD device image file, /home/ubuntu/Images/OSMC-4gb-SD-20170117.sources.
.PARAMETER FilePath
    Path to the OSMC image file. Please keep the original name as the cmdlet depends on it.
.PARAMETER CustomSettings
    Hashtable containing custom settings, these settings will be set as settings in the config.txt file.
.PARAMETER RestoreFilePath
    Path to the backup file.
.PARAMETER USBDevicePath
    Path to the USB device, e.g. /dev/sdc.
.PARAMETER USBDeviceFilePath
    Path to the USB device image file, /home/ubuntu/Images/OSMC-16gb-USB-20170117.sources.
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

    dynamicParam {
        $dictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
        
        if ($SDDevicePath -match '^/dev/loop\d{1}$') {
            $parameterName = 'SDDeviceFilePath'

            $attributes = [Parameter]::new()
            $attributes.Mandatory = $true
            $attributes.ParameterSetName = '__AllParameterSets'

            $attributeCollection = [Collections.ObjectModel.Collection[Attribute]]@(
                $attributes
                [ValidateScript]::new({
                    Test-Path -Path $_ -PathType Leaf
                })
            )

            $parameter = [Management.Automation.RuntimeDefinedParameter]::new(
                $parameterName,
                [string],
                $attributeCollection
            )

            $dictionary.Add($parameterName, $parameter)
        }

        if ($USBDevicePath -match '^/dev/loop\d{1}$') {
            $parameterName = 'USBDeviceFilePath'

            $attributes = [Parameter]::new()
            $attributes.Mandatory = $true
            $attributes.ParameterSetName = 'USB'

            $attributeCollection = [Collections.ObjectModel.Collection[Attribute]]@(
                $attributes
                [ValidateScript]::new({
                    Test-Path -Path $_ -PathType Leaf
                })
            )

            $parameter = [Management.Automation.RuntimeDefinedParameter]::new(
                $parameterName,
                [string],
                $attributeCollection
            )

            $dictionary.Add($parameterName, $parameter)
        }

        $dictionary
    }
    
    begin {

        try {

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice -eq $null) {
                throw "Cannot find device '$SDDevicePath' because it does not exist."
            }

            if ($PSBoundParameters.ContainsKey('SDDeviceFilePath')) {
                [Losetup]::Attach($SDDevice, $PSBoundParameters.SDDeviceFilePath)
                $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            }

            if ($PSCmdlet.ParameterSetName -eq 'USB') {
                $USBDevice = [DeviceService]::GetDevice($USBDevicePath)
                if ($USBDevice -eq $null) {
                    throw "Cannot find device '$USBDevicePath' because it does not exist."
                }

                if ($PSBoundParameters.ContainsKey('USBDeviceFilePath')) {
                    [Losetup]::Attach($USBDevice, $PSBoundParameters.USBDeviceFilePath)
                    $USBDevice = [DeviceService]::GetDevice($USBDevicePath)
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

                if ($PSBoundParameters.ContainsKey('USBDeviceFilePath')) {
                    [Losetup]::Detach($USBDevice)
                }
            }

            if ($PSBoundParameters.ContainsKey('SDDeviceFilePath')) {
                [Losetup]::Detach($SDDevice)
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
                $key = 'SDDeviceFilePath'
            } else {
                $devicePath = $USBDevicePath
                $index = 0
                $key = 'USBDeviceFilePath'
            }

            if ($PSBoundParameters.ContainsKey($key)) {
                $device = [DeviceService]::GetDevice($devicePath)
                [Losetup]::Attach($device, $PSBoundParameters.Item($key))
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

            [Losetup]::Attach($loop, $file.FullName)

            [Partprobe]::Probe($loop)

            $loop = [DeviceService]::GetDevice($loopPath)

            [Utility]::Mount($loop.GetPartition(0), $source)

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

            if ($PSBoundParameters.ContainsKey($key)) {
                [Losetup]::Detach($device)
            }

            $loop = [DeviceService]::GetDevice($loopPath)
            if ($loop.GetPartition(0).Umount()) {
                [Utility]::Umount($loop.GetPartition(0))
            }

            [Losetup]::Detach($loop)

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

            if ($PSBoundParameters.ContainsKey('SDDeviceFilePath')) {
                [Losetup]::Attach($SD, $PSBoundParameters.SDDeviceFilePath)
                $SD = [DeviceService]::GetDevice($SDDevicePath)
            }

            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SD.GetPartition(0), $destination)

            if ($PSCmdlet.ParameterSetName -eq 'SD') {

                [Utility]::Mount($SD.GetPartition(1), $source)

                Copy-Item   -Path "$source/boot/*" -Destination "$destination/" -Recurse
                Remove-Item -Path "$source/boot/*" -Recurse

                $SD = [DeviceService]::GetDevice($SDDevicePath)
                if ($SD.GetPartition(1).Umount()) {
                    [Utility]::Umount($SD.GetPartition(1))
                }

            } else {

                $USB = [DeviceService]::GetDevice($USBDevicePath)

                if ($PSBoundParameters.ContainsKey('USBDeviceFilePath')) {
                    [Losetup]::Attach($USB, $PSBoundParameters.USBDeviceFilePath)
                    $USB = [DeviceService]::GetDevice($USBDevicePath)
                }

                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }

                $USB = [DeviceService]::GetDevice($USBDevicePath)

                [Utility]::Mount($USB.GetPartition(0), $source)

                Copy-Item   -Path "$source/boot/*" -Destination "$destination/" -Recurse
                Remove-Item -Path "$source/boot/*" -Recurse

                $USB = [DeviceService]::GetDevice($USBDevicePath)
                if ($USB.GetPartition(0).Umount()) {
                    [Utility]::Umount($USB.GetPartition(0))
                }

                if ($PSBoundParameters.ContainsKey('USBDeviceFilePath')) {
                    [Losetup]::Detach($USB)
                }
            }

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

            $SD = [DeviceService]::GetDevice($SDDevicePath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            if ($PSBoundParameters.ContainsKey('SDDeviceFilePath')) {
                [Losetup]::Detach($SDDevice)
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
                    $key = 'SDDeviceFilePath'
                } else {
                    $devicePath = $USBDevicePath
                    $index = 0
                    $key = 'USBDeviceFilePath'
                }

                if ($PSBoundParameters.ContainsKey($key)) {
                    $device = [DeviceService]::GetDevice($devicePath)
                    [Losetup]::Attach($device, $PSBoundParameters.Item($key))
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

                if ($PSBoundParameters.ContainsKey($key)) {
                    [Losetup]::Detach($device)
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
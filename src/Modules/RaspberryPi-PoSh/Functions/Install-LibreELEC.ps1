<#
.SYNOPSIS
    Installs and restores LibreELEC.
.DESCRIPTION
    This cmdlet installs and optionally restores LibreELEC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Use this cmdlet to install LibreELEC to SD or USB.
    
    The cmdlet supports two of the three types of LibreELEC distribution image file formats. The first being the .tar (LibreELEC-RPi2.arm-<version>.tar) and the noobs archive format (LibreELEC-RPi2.arm-<version>-noobs.tar.

    The cmdlet can do installs for all Raspberry Pi versions.

    The cmdlet also supports installing to loop devices, to do this you have to prepare an empty image file before executing the cmdlet and pointing it to the image file using either the SDDeviceFilePath or the USBDeviceFilePath dynamic parameter. The SDDeviceFilePath or USBDeviceFilePath parameters are only available when either or both the SDDevicePath or USBDevicePath parameters are pointing to a loop back device, see the examples for more information about this functionality.

    Note that when doing image provisioning the SDDevicePath or USBDevicePath must point to a free loop device.
.EXAMPLE
    PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'

    This example shows how to do a typical install of LibreELEC.
.EXAMPLE
    PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'

    This example shows how to do an install to USB version of LibreELEC.
.EXAMPLE
    PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}

    This example shows how to do a typical LibreELEC install with custom settings.
.EXAMPLE
    PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320} -RestoreFilePath '/home/ubuntu/Kodi/Backup/LibreELEC-20161210133450.tar'

    This example shows how to do an advanced LibreELEC install to USB, specify custom settings and also restoring a previously taken backup.
.EXAMPLE
    PS /> Install-LibreELEC -SDDevicePath '/dev/loop0' -SDDeviceFilePath '/home/ubuntu/Images/LibreELEC-4gb-SD-20170117.img' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'

    This example shows how to install LibreELEC using loopback devices.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER SDDeviceFilePath
    Path to the SD device image file, /home/ubuntu/Images/LibreELEC-4gb-SD-20170117.img.
.PARAMETER FilePath
    Path to the LibreELEC image file. Please keep the original name as the cmdlet depends on it.
.PARAMETER CustomSettings
    Hashtable containing custom settings, these settings will be set as settings in the config.txt file.
.PARAMETER RestoreFilePath
    Path to the backup file.
.PARAMETER USBDevicePath
    Path to the USB device, e.g. /dev/sdc.
.PARAMETER USBDeviceFilePath
    Path to the USB device image file, /home/ubuntu/Images/LibreELEC-16gb-USB-20170117.img.
.LINK
    https://haydenjames.io/raspberry-pi-2-overclock/
    https://haydenjames.io/raspberry-pi-3-overclock/
#>
function Install-LibreELEC {
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

                [mkfs]::Ext4($USBDevice.GetPartition(0), 'STORAGE')
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

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            if ($PSBoundParameters.ContainsKey('SDDeviceFilePath')) {
                [Losetup]::Attach($SDDevice, $PSBoundParameters.SDDeviceFilePath)
                $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            }

            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
            }

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            [Utility]::Mount($SDDevice.GetPartition(0), $destination)

            $file = Get-Item -Path $FilePath

            if ($file.Name -like '*noobs*') {
                [Tar]::Extract($file.FullName, $source)

                $file = Get-ChildItem -Path $source -Recurse | Where-Object {$_.Name -imatch 'System\.tar\.xz$'} | Select-Object -First 1

                [Tar]::Extract($file.FullName, $destination)
            } else {
                [Tar]::Extract($file.FullName, $source)

                $source2 = Join-Path -Path $source -ChildPath $file.BaseName

                Copy-Item -Path "$source2/target/KERNEL"            -Destination "$destination/kernel.img"
                Copy-Item -Path "$source2/target/KERNEL.md5"        -Destination "$destination/kernel.img.md5"
                Copy-Item -Path "$source2/target/SYSTEM"            -Destination "$destination/"
                Copy-Item -Path "$source2/target/SYSTEM.md5"        -Destination "$destination/SYSTEM.md5"
                Copy-Item -Path "$source2/README.md"                -Destination "$destination/"
                Copy-Item -Path "$source2/licenses"                 -Destination "$destination/" -Recurse
                Copy-Item -Path "$source2/3rdparty/bootloader/*"    -Destination "$destination/" -Recurse

                $(Get-Content -Path "$destination/kernel.img.md5")  -replace 'target/KERNEL', 'kernel.img' | Set-Content -Path "$destination/kernel.img.md5"
                $(Get-Content -Path "$destination/SYSTEM.md5")      -replace 'target/SYSTEM', 'SYSTEM' | Set-Content -Path "$destination/SYSTEM.md5"

                [Md5sum]::Check("$destination/kernel.img.md5")
                [Md5sum]::Check("$destination/SYSTEM.md5")
            }

            Remove-Item -Path $source -Recurse -Force

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)

            "boot=LABEL=SYSTEM disk=LABEL=STORAGE quiet" | Set-Content -Path "$destination/cmdline.txt" -Force

            if ($PSBoundParameters.ContainsKey('CustomSettings')) {
                $configFile = [ConfigFile]::new($destination)
                $configFile.SetCustomSettings($CustomSettings)
                $configFile.Save()
            }

            [Utility]::Sync()

            $SDDevice = [DeviceService]::GetDevice($SDDevicePath)
            if ($SDDevice.GetPartition(0).Umount()) {
                [Utility]::Umount($SDDevice.GetPartition(0))
            }

            if ($PSBoundParameters.ContainsKey('SDDeviceFilePath')) {
                [Losetup]::Detach($SDDevice)
            }

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
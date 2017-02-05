Set-StrictMode -Version Latest
Set-PSDebug -Strict

<#
.SYNOPSIS
    Installs and restores OpenELEC.
.DESCRIPTION
    This cmdlet installs and optionally restores OpenELEC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Use this cmdlet to install OpenELEC to SD or USB.

    The cmdlet supports the OpenELEC tar distribution image file format (OpenELEC-RPi*.arm-*.tar).

    The cmdlet can install all Raspberry Pi versions.
.EXAMPLE
    PS /> Install-OpenELEC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar'

    This example shows how to do a typical install of OpenELEC.
.EXAMPLE
    PS /> Install-OpenELEC -SDDevicePath '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar'

    This example shows how to do an install to USB of OpenELEC.
.EXAMPLE
    PS /> Install-OpenELEC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}

    This example shows how to do a typical install of OpenELEC and specifying some custom settings.
.EXAMPLE
    PS /> Install-OpenELEC -SDDevicePath '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320} -RestoreFilePath '/home/ubuntu/Kodi/Backup/OpenELEC-20161210133450.tar'

    This example shows how to do advanced install of OpenELEC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.
.EXAMPLE
    PS /> Install-OpenELEC -SDDevicePath '/dev/loop0' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar'

    This example shows how to install OpenELEC using a loopback device. Notice that before executing the cmdlet, you will have to manually attach the disk image to the loopback device and afterwards execute the cmdlets indicating the loopback device you have attached the disk image. In this example we have attached the disk image to /dev/loop0.
.PARAMETER SDDevicePath
    Path to the SD device, e.g. /dev/mmcblk0.
.PARAMETER FilePath
    Path to the OpenELEC image file.
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
function Install-OpenELEC {
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

            $file = Get-Item -Path $FilePath

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

            Remove-Item -Path $source -Recurse -Force

            $SD = [DeviceService]::GetDevice($SDDevicePath)

            "boot=LABEL=SYSTEM disk=LABEL=STORAGE quiet" | Set-Content -Path "$destination/cmdline.txt" -Force

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
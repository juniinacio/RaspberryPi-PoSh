<#
.SYNOPSIS
    Creates an LibreELEC image file.
.DESCRIPTION
    This cmdlet creates an LibreELEC image file than can be restored using dd or Win32DiskImager.
    
    The cmdlet supports two of the three types of LibreELEC distribution image file formats. The first being the .tar (LibreELEC-RPi2.arm-<version>.tar) and the noobs archive format (LibreELEC-RPi2.arm-<version>-noobs.tar.

    The cmdlet can create image files for all Raspberry Pi versions.
.EXAMPLE
    PS /> New-LibreELECImage -SDDeviceFilePath "/home/ubuntu/LibreELEC/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'

    This example shows how to create a 4gb LibreELEC image for your SD device.
.EXAMPLE
    PS /> New-LibreELECImage -SDDeviceFilePath "/home/ubuntu/LibreELEC/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -USBDeviceFilePath "/home/ubuntu/LibreELEC/LibreELEC-USB-Image.img" -USBDeviceSize 8gb -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -RestoreFilePath '/home/ubuntu/Kodi/Backup/LibreELEC-20161210133450.tar'

    This example shows how to create a 4gb LibreELEC image for your SD device, a 8gb image for your USB device.
.PARAMETER SDDeviceFilePath
    Path to store the SD device image file, e.g. /home/ubuntu/Images/LibreELEC-SD-Image.img.
.PARAMETER SDDeviceSize
    SD image file size in bytes. This must be equal to or less than the actual size of your SD device.
.PARAMETER FilePath
    Path to the LibreELEC image file.
.PARAMETER CustomSettings
    Hashtable containing custom settings, these settings will be applied to the config.txt file.
.PARAMETER RestoreFilePath
    Path to the backup file.
.PARAMETER USBDeviceFilePath
    Path to store the USB device image file, e.g. /home/ubuntu/Images/LibreELEC-USB-Image.img.
.PARAMETER USBDeviceSize
    USB image file size in bytes. This must be equal to or less than the actual size of your USB device.
#>
function New-LibreELECImage {
    [CmdletBinding(
        DefaultParameterSetName = 'SD'
    )]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'SD')]
        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SDDeviceFilePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'SD')]
        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [long]
        $SDDeviceSize,

        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [string]
        $USBDeviceFilePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'USB')]
        [ValidateNotNullOrEmpty()]
        [long]
        $USBDeviceSize,

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

            [Utility]::DD('/dev/zero', $SDDeviceFilePath, 1048576, $($SDDeviceSize/1048576))

            $file = Get-Item -Path $SDDeviceFilePath

            $SDPath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDPath)

            [Losetup]::Attach($SD.GetPath(), $file.FullName)

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
 
            $SD = [DeviceService]::GetDevice($SDPath)

            [Mkfs]::VFat($SD.GetPartition(0), 'SYSTEM', 32)

            if ($PSCmdlet.ParameterSetName -eq 'SD') {
                [Mkfs]::Ext4($SD.GetPartition(1), 'STORAGE')
            } else {
                [Utility]::DD('/dev/zero', $USBDeviceFilePath, 1048576, $($USBDeviceSize/1048576))
                
                $file = Get-Item -Path $USBDeviceFilePath

                $USBPath = [Losetup]::Lookup()

                $USB = [DeviceService]::GetDevice($USBPath)

                [Losetup]::Attach($USB.GetPath(), $file.FullName)

                [Parted]::MKLabel($USB, 'msdos')

                [Parted]::MKPart($USB, 'primary', 'cyl', 'ext2', 0, -2)

                if (-not ([Parted]::Aligncheck($USB, 'opt', 1))) {
                    Write-Error "Device '$($USB.GetPartition(0))' is not aligned."
                }

                [Partprobe]::Probe($USB)

                $USB = [DeviceService]::GetDevice($USBPath)

                [mkfs]::Ext4($USB.GetPartition(0), 'STORAGE')

                [Losetup]::Detach($USB.GetPath())
            }

            [Losetup]::Detach($SD.GetPath())

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

            $file = Get-Item -Path $SDDeviceFilePath

            $SDPath = [Losetup]::Lookup()

            $SD = [DeviceService]::GetDevice($SDPath)

            [Losetup]::Attach($SD.GetPath(), $file.FullName)

            [Partprobe]::Probe($SD)

            $SD = [DeviceService]::GetDevice($SDPath)

            [Utility]::Mount($SD.GetPartition(0), $destination)

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

            "boot=LABEL=SYSTEM disk=LABEL=STORAGE quiet" | Set-Content -Path "$destination/cmdline.txt" -Force

            if ($PSBoundParameters.ContainsKey('CustomSettings')) {
                $configFile = [ConfigFile]::new($destination)
                $configFile.SetCustomSettings($CustomSettings)
                $configFile.Save()
            }

            [Utility]::Sync()

            $SD = [DeviceService]::GetDevice($SDPath)
            if ($SD.GetPartition(0).Umount()) {
                [Utility]::Umount($SD.GetPartition(0))
            }

            [Losetup]::Detach($SD.GetPath())

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
                    $file = Get-Item -Path $SDDeviceFilePath
                    $index = 1
                } else {
                    $file = Get-Item -Path $USBDeviceFilePath
                    $index = 0
                }

                $devicePath = [Losetup]::Lookup()

                $device = [DeviceService]::GetDevice($devicePath)

                [Losetup]::Attach($device.GetPath(), $file.FullName)

                [Partprobe]::Probe($device)

                $device = [DeviceService]::GetDevice($devicePath)

                [Utility]::Mount($device.GetPartition($index), $destination)

                $file = Get-Item -Path $RestoreFilePath
                
                [Tar]::Extract($file.FullName, $destination)

                [Utility]::Sync()

                $device = [DeviceService]::GetDevice($SDPath)
                if ($device.GetPartition($index).Umount()) {
                    [Utility]::Umount($device.GetPartition($index))
                }

                [Losetup]::Detach($device.GetPath())

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
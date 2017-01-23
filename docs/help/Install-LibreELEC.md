# Install-LibreELEC
Installs and restores LibreELEC.

## Description
This cmdlet installs and optionally restores LibreELEC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Use this cmdlet to install LibreELEC to SD or USB.
    
The cmdlet supports two of the three types of LibreELEC distribution image file formats. The first being the .tar (LibreELEC-RPi*.arm-*.tar) and the noobs archive format (LibreELEC-RPi*.arm-*-noobs.tar.

The cmdlet can install all Raspberry Pi versions.

## Syntax
```powershell
Install-LibreELEC   -SDDevicePath <String>
                    -FilePath <String>
                    [-CustomSettings <Hashtable>]
                    [-RestoreFilePath <String>]
                    [<CommonParameters>]
```
```powershell
Install-LibreELEC   -SDDevicePath <String>
                    -USBDevicePath <String>
                    -FilePath <String>
                    [-CustomSettings <Hashtable>]
                    [-RestoreFilePath <String>]
                    [<CommonParameters>]
```

## Parameters
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDevicePath|String|True|Path to the SD device, e.g. /dev/mmcblk0.|
|FilePath|String|True|Path to the LibreELEC image file.|
|CustomSettings|Hashtable|False|Hashtable containing custom settings, these settings will be set as settings in the config.txt file.|
|RestoreFilePath|String|False|Path to the backup file.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|

### Example 1
```powershell
PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'
```
This example shows how to do a typical install of LibreELEC.

### Example 2
```powershell
PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'
```
This example shows how to do an install to USB of LibreELEC.

### Example 3
```powershell
PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}
```
This example shows how to do a typical install of LibreELEC and specifying some custom settings.

### Example 4
```powershell
PS /> Install-LibreELEC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320} -RestoreFilePath '/home/ubuntu/Kodi/Backup/LibreELEC-20161210133450.tar'
```
This example shows how to do advanced install of LibreELEC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.

### Example 5
```powershell
PS /> Install-LibreELEC -SDDevicePath '/dev/loop0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'
```
This example shows how to install LibreELEC using a loopback device. Notice that before executing the cmdlet, you will have to manually attach the disk image to the loopback device and afterwards execute the cmdlets indicating the loopback device you have attached the disk image. In this example we have attached the disk image to /dev/loop0.

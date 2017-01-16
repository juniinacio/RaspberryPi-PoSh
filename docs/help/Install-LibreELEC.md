# Install-LibreELEC
Installs and restores LibreELEC

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

### Parameters
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDevicePath|String|True|Path to the SD device, e.g. /dev/mmcblk0.|
|FilePath|String|True|Path to the LibreELEC image file.|
|CustomSettings|Hashtable|False|Hashtable containing custom settings, these settings will be set as settings in the config.txt file.|
|RestoreFilePath|String|False|Path to the backup file.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|

### Example 1
```powershell
PS /> Install-LibreELEC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'
```
This example shows how to do a typical install of LibreELEC.

### Example 2
```powershell
PS /> Install-LibreELEC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'
```
This example shows how to do an install to USB of LibreELEC.

### Example 3
```powershell
PS /> Install-LibreELEC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}
```
This example shows how to do a typical install of LibreELEC and specifying some custom settings.

### Example 4
```powershell
PS /> Install-LibreELEC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320} -RestoreFilePath '/home/ubuntu/Kodi/Backup/LibreELEC-20161210133450.tar'
```
This example shows how to do advanced install of LibreELEC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.

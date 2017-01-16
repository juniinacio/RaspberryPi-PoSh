# Install-OpenELEC
Installs and restores OpenELEC

## Syntax
```powershell
Install-OpenELEC    -SDDevicePath <String>
                    -FilePath <String>
                    [-CustomSettings <Hashtable>]
                    [-RestoreFilePath <String>]
                    [<CommonParameters>]
```
```powershell
Install-OpenELEC    -SDDevicePath <String>
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
|FilePath|String|True|Path to the OpenELEC image file.|
|CustomSettings|Hashtable|False|Hashtable containing custom settings, these settings will be set as settings in the config.txt file.|
|RestoreFilePath|String|False|Path to the backup file.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|

### Example 1
```powershell
PS /> Install-OpenELEC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar'
```
This example shows how to do a typical install of OpenELEC.

### Example 2
```powershell
PS /> Install-OpenELEC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar'
```
This example shows how to do an install to USB of OpenELEC.

### Example 3
```powershell
PS /> Install-OpenELEC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}
```
This example shows how to do a typical install of OpenELEC and specifying some custom settings.

### Example 4
```powershell
PS /> Install-OpenELEC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OpenELEC-RPi2.arm-6.0.3.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320} -RestoreFilePath '/home/ubuntu/Kodi/Backup/OpenELEC-20161210133450.tar'
```
This example shows how to do advanced install of OpenELEC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.

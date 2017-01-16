# Install-OSMC
Installs and restores OSMC

## Syntax
```powershell
Install-OSMC    -SDDevicePath <String>
                -FilePath <String>
                [-CustomSettings <Hashtable>]
                [-RestoreFilePath <String>]
                [<CommonParameters>]
```
```powershell
Install-OSMC    -SDDevicePath <String>
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
|FilePath|String|True|Please keep the original name as the cmdlet depends on it.|
|CustomSettings|Hashtable|False|Hashtable containing the custom settings, this settings will be applied to the config.txt file.|
|RestoreFilePath|String|False|Path to the backup file.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|

### Example 1
```powershell
PS /> Install-OSMC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'
```
This example shows how to do a typical install of OSMC.

### Example 2
```powershell
PS /> Install-OSMC -SD '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}
```
This example shows how to do an install to USB of OSMC.

### Example 3
```powershell
PS /> Install-OSMC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}
```
This example shows how to do a typical install of OSMC and specifying some custom settings.

### Example 4
```powershell
PS /> Install-OSMC -SD '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Kodi/Backup/OpenELEC-20161214183622.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}
```
This example shows how to do advanced install of OSMC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.
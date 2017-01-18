# Install-OSMC
Installs and restores OSMC.

## Description
This cmdlet installs and restores OSMC for the Raspberry Pi. This cmdlet also support setting custom settings into the config.txt file. Using this cmdlet u will be able to do both a SD or USB install of OSMC.
    
The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp2_20161128.sources.gz).

The cmdlet can do installs for all Raspberry Pi versions.

OSMC can be downloaded from one of the following locations:
http://download.osmc.tv/
http://download.osmc.tv/installers/diskimages/ (direct link)

The cmdlet also supports installing to loop devices, to do this you have to prepare an empty image file before executing the cmdlet and pointing it to the image file using either the SDDeviceFilePath or the USBDeviceFilePath dynamic parameter. The SDDeviceFilePath or USBDeviceFilePath parameters are only available when either or both the SDDevicePath or USBDevicePath parameters are pointing to a loop back device, see the examples for more information about this functionality.

Note that when doing image provisioning the SDDevicePath or USBDevicePath must point to a free loop device.

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

## Parameters
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDevicePath|String|True|Path to the SD device, e.g. /dev/mmcblk0.|
|SDDeviceFilePath|String|True|Path to the SD device image file, /home/ubuntu/Images/OSMC-4gb-SD-20170117.sources.|
|FilePath|String|True|Please keep the original name as the cmdlet depends on it.|
|CustomSettings|Hashtable|False|Hashtable containing the custom settings, this settings will be applied to the config.txt file.|
|RestoreFilePath|String|False|Path to the backup file.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|
|USBDeviceFilePath|String|True|Path to the USB device image file, /home/ubuntu/Images/OSMC-16gb-USB-20170117.sources.|

### Example 1
```powershell
PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'
```
This example shows how to do a typical install of OSMC.

### Example 2
```powershell
PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -USBDevicePath '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}
```
This example shows how to do an install to USB of OSMC.

### Example 3
```powershell
PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2;gpu_mem=320}
```
This example shows how to do a typical install of OSMC and specifying some custom settings.

### Example 4
```powershell
PS /> Install-OSMC -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Kodi/Backup/OpenELEC-20161214183622.tar' -CustomSettings @{arm_freq=1000;core_freq=500;sdram_freq=500;over_voltage=2}
```
This example shows how to do advanced install of OSMC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.

### Example 5
```powershell
PS /> Install-OSMC -SDDevicePath '/dev/loop0' -SDDeviceFilePath '/home/ubuntu/Images/OSMC-4gb-SD-20170117.img' -USBDevicePath '/dev/loop1' -USBDeviceFilePath '/home/ubuntu/Images/OSMC-16gb-USB-20170117.img' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -RestoreFilePath '/home/ubuntu/Backups/OSMC-20161223084639.tar'
```
This example shows how to install OSMC to USB using loop devices.
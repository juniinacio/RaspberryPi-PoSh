# Install-OSMC #
Installs OSMC installer.

### Description ###
This cmdlet installs the OSMC installer the Raspberry Pi. Installing OSMC using this cmdlet has the same affect as using the Official OSMC installer.
    
The cmdlet supports the OSMC tar distribution image file format (OSMC_TGT_rbp*_*.img.gz).

The cmdlet can do installs for all Raspberry Pi versions.

OSMC can be downloaded from one of the following locations:
http://download.osmc.tv/
http://download.osmc.tv/installers/diskimages/ (direct link)

### Syntax ###
```powershell
Install-OSMCInstaller -SDDevicePath <String> [-USB] -FilePath <String> [<CommonParameters>]
```
```powershell
Install-OSMCInstaller -SDDevicePath <String> [-USB] -FilePath <String> -WLAN [-KeyType <String>] [-Key <String>] -SSID <String> [<CommonParameters>]
```

### Parameters ###
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDevicePath|String|True|Path to the SD device, e.g. /dev/mmcblk0.|
|FilePath|String|True|Path to the OSMC image file.|
|WLAN|Switch|False|Specifies that wireless should be used.|
|USB|Switch|False|Specifies to install to USB.|
|KeyType|String|False|Specifies the encryption type of the wireless network.|
|Key|String|True|Specifies the password of the wireless network.|
|SSID|String|True|Specifies the SSID of the wireless network.|

### Example 1 ###
```powershell
PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'
```
This example shows how to do a typical OSMC install.

### Example 2 ###
```powershell
PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -USB '/dev/sdc' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz'
```
This example shows how to do an install to USB.

### Example 3 ###
```powershell
PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'MyNetwork'
```
This example shows how to install to SD and configure WiFi.

### Example 4 ###
```powershell
PS /> Install-OSMCInstaller -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Downloads/OSMC_TGT_rbp2_20161128.img.gz' -WLAN -KeyType 'WPA/WPA2_PSK' -Key '123456' -SSID  'MyNetwork'
```
This example shows how to do advanced install of OSMC, specifying some custom settings and also doing a restore from a previously taken backup using the Backup-Raspberry cmdlet.
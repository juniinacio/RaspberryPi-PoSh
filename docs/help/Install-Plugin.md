# Install-Plugin
Installs Kodi addons.

## Description
This cmdlet can be use to install or more addons into an existing Raspberry Pi Kodi installation.

This cmdlet expects the addons to be in a zipped (.zip) format, also the cmdlet does a basic validation of the addons structure.

## Syntax
```powershell
Install-Plugin  -SDDevicePath <String>
                [-FilePath <String[]>]
                [-ExcludeFilePath <String>]
                [<CommonParameters>]
```

```powershell
Install-Plugin  -USBDevicePath <String>
                [-FilePath <String[]>]
                [-ExcludeFilePath <String>]
                [<CommonParameters>]
```

## Parameters
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDevicePath|String|True|Path to the SD device, e.g. /dev/mmcblk0.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|
|FilePath|String|True|Path to the addon file, e.g /home/ubuntu/Downloads/plugin.video.youtube.zip.|

### Example 1
```powershell
PS /> Install-Plugin -SDDevicePath '/dev/mmcblk0' -Path '/home/ubuntu/Downloads/plugin.video.youtube.zip'
```
This example shows how to install a Kodi plugin to SD.

### Example 2
```powershell
PS /> Install-Plugin -USBDevicePath '/dev/sdc' -Path '/home/ubuntu/Downloads/plugin.video.youtube.zip'
```
This example shows how to install a Kodi plugin to USB.

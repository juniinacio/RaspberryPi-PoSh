# New-LibreELECImage
Creates a LibreELEC image

## Syntax
```powershell
New-LibreELECImage  -SDDeviceFilePath <String>
                    -SDDeviceSize <Int64>
                    -FilePath <String>
                    [-CustomSettings <Hashtable>]
                    [-RestoreFilePath <String>]
                    [<CommonParameters>]
```
```powershell
New-LibreELECImage  -SDDeviceFilePath <String>
                    -SDDeviceSize <Int64>
                    -USBDeviceFilePath <String>
                    -USBDeviceSize <Int64>
                    -FilePath <String> 
                    [-CustomSettings <Hashtable>]
                    [-RestoreFilePath <String>] 
                    [<CommonParameters>]
```

### Parameters
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDeviceFilePath|String|True|Path to store the SD device image file, e.g. /home/ubuntu/Images/LibreELEC-SD-Image.img.|
|SDDeviceSize|Int64|True|SD image file size in bytes. This must be equal to or less than the actual size of your SD device.|
|FilePath|String|True|Path to the LibreELEC image file.|
|CustomSettings|Hashtable|False|Hashtable containing custom settings, these settings will be applied to the config.txt file.|
|RestoreFilePath|String|False|Path to the backup file.|
|USBDeviceFilePath|String|True|Path to store the USB device image file, e.g. /home/ubuntu/Images/LibreELEC-USB-Image.img.|
|USBDeviceSize|Int64|True|USB image file size in bytes. This must be equal to or less than the actual size of your USB device.|

### Example 1
```powershell
PS /> New-LibreELECImage -SDDeviceFilePath "/home/ubuntu/LibreELEC/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar'
```

This example shows how to create a 4gb LibreELEC image for your SD device.

### Example 2
```powershell
PS /> New-LibreELECImage -SDDeviceFilePath "/home/ubuntu/LibreELEC/LibreELEC-SD-Image.img" -SDDeviceSize 4gb -USBDeviceFilePath "/home/ubuntu/LibreELEC/LibreELEC-USB-Image.img" -USBDeviceSize 8gb -FilePath '/home/ubuntu/Downloads/LibreELEC-RPi2.arm-7.0.2.tar' -RestoreFilePath '/home/ubuntu/Kodi/Backup/LibreELEC-20161210133450.tar'
```

This example shows how to create a 4gb LibreELEC image for your SD device, a 8gb image for your USB device.
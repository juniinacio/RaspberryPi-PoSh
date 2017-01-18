# Backup-Raspberry
Creates a backup of the Kodi installation on the Raspberry Pi.

# Description
This cmdlet Creates a backup of the Kodi installation on the Raspberry Pi. Use this cmdlet together with the Install-LibreELEC, Install-OpenELEC or Install-OSMC cmdlets to
restore your Raspberry Pi in case of an emergency or new install.

## Syntax
```powershell
Backup-Raspberry    -SDDevicePath <String>
                    [-FilePath <String>]
                    [-ExcludeFilePath <String>]
                    [<CommonParameters>]
```

```powershell
Backup-Raspberry    -USBDevicePath <String>
                    [-FilePath <String>]
                    [-ExcludeFilePath <String>]
                    [<CommonParameters>]
```

## Parameters
Parameter|Type|Required|Description
---------|----|--------|-----------
|SDDevicePath|String|True|Path to the SD device, e.g. /dev/mmcblk0.|
|USBDevicePath|String|True|Path to the USB device, e.g. /dev/sdc.|
|FilePath|String|False|Path to the backup file.|
|ExcludeFilePath|String|False|Path to the exclude file. For more information about the -ExcludeFilePath parameter see tar -X command.|

### Example 1
```powershell
PS /> Backup-Raspberry -SDDevicePath '/dev/mmcblk0' -FilePath '/home/ubuntu/Backups/Kodi-20161223084639.tar'
```
This example shows how to take a backup of your Kodi installation when installed to SD.

### Example 2
```powershell
PS /> Backup-Raspberry -USBDevicePath '/dev/sdc' -ExcludeFilePath '/home/ubuntu/Documents/ExcludeFile.txt'
```
This example shows how to take a backup of your Kodi installation when installed to USB. For more information about the -ExcludeFilePath parameter see tar -X command.

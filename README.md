## ![logo][] RaspberryPi-PoSh ##

[logo]: assets/Raspberry_Pi_64.png

Welcome to the RaspberryPi-PoSh github repository. RaspberryPi-PoSh is a PowerShell v6 module for installing Kodi on the Raspberry Pi using a Linux-, macOS- based operating systems. This module supports installing the following Kodi distributions:
- LibreELEC
- OpenELEC
- OSMC

### Prerequisites ###
In order to use this module you need to have PowerShell installed on your system, which you can download [here][download-powershell].

[download-powershell]: https://github.com/PowerShell/PowerShell

*Notice: This module has been only tested under Ubuntu 14.01, Ubuntu 16.04 and CentOS 7 (feel free to test it under macOS and letting me know).*

### New to PowerShell? ###
If you are new to PowerShell and would like to learn more, I recommend reviewing the [getting started][getting-started] documentation.

[getting-started]: https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell

### Cmdlets included ###
Navigate [here][get-help] for an overview of all cmdlets and their parameters, off course every cmdlets has built-in help integrated, feel free to use get-help.

[get-help]: docs/help/README.md

### Installation ###
1. Download or clone this repository on your desktop.
2. Copy the directory RaspberryPi-PoSh to one of the following directories:
  * /home/ubuntu/.local/share/powershell/Modules
  * /usr/local/share/powershell/Modules
  * /opt/microsoft/powershell/[version]/Modules

*Notice: For a up to date list where you can copy the module directory, execute the following command at the Windows PowerShell command prompt:*
```powershell
$Env:PSMODULEPATH -Split ":"
```

### Getting started ###
To use the module you first need to import it in your current PowerShell session:
```powershell
Import-Module -Name RaspberryPi-PoSh
```
To view all cmdlets, enter:
```powershell
Get-Command -Module RaspberryPi-PoSh
```

### Creating disk images? ###
See this [wiki page](https://github.com/juniinacio/RaspberryPi-PoSh/wiki/Working-with-images) for more information on how to use classes available in this module to create disk images for your Raspberry Pi.

*Notice: Start PowerShell as root when using the module!*
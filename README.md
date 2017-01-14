![logo][] RaspberryPi-PoSh
====================

[logo]: assets/Raspberry_Pi_64.png

Welcome to the PowerShell v6 module for provisioning Kodi on the Raspberry Pi.

About
-----
RaspberryPi-PoSh is a PowerShell v6 module for provisioning Kodi onto the Raspberry Pi under Linux-, macOS- based systems.

The reason I created this module is that I wanted to easily backup my Raspberry Pi, install/re-install it or in case of corruption, do a full restore. I also wanted the possibility to update the device for family and friends.

I sucked with bash, so when Microsoft released PowerShell for Linux, I saw the opportunity to rewrite my poor bash scripts to PowerShell.

Prerequisites
-------------
In order to use this module you need to have PowerShell installed on your system, which you can download [here][download-powershell].

[download-powershell]: https://github.com/PowerShell/PowerShell

*Notice: This module has been tested under Ubuntu 14.01, Ubuntu 16.04 and CentOS 7 only (feel free to test under macOS).*

New to PowerShell?
------------------
If you are new to PowerShell and would like to learn more, I recommend reviewing the [getting started][getting-started] documentation.

[getting-started]: https://github.com/PowerShell/PowerShell/tree/master/docs/learning-powershell

Cmdlets included
----------------
Navigate [here][get-help] for an overview of all cmdlets and their parameters, off course every cmdlets has built-in help integrated, feel free to use get-help.

[get-help]: docs/help/README.md

Installation
------------
1. Download or clone this repository on your desktop.
2. Copy the directory src/Modules/RaspberryPi-PoSh to one of the following directories:
  * /home/ubuntu/.local/share/powershell/Modules
  * /usr/local/share/powershell/Modules
  * /opt/microsoft/powershell/[version]/Modules

*Notice: For a up to date list where you can copy the module directory, execute the following command at the Windows PowerShell command prompt:*
```powershell
$Env:PSMODULEPATH -Split ":"
```

Alternatively you can use the [install.ps1][install-ps1] contained in the root of the repository to automatically copy the module directory.

*Notice: By default the script copies the module directory into '/usr/local/share/powershell/Modules'.*

[install-ps1]: install.ps1

Getting started
---------------

To use the module you first need to import it in your current PowerShell session:
```powershell
Import-Module -Name RaspberryPi-PoSh
```
To view all cmdlets, enter:
```powershell
Get-Command -Module RaspberryPi-PoSh
```

*Notice: Start PowerShell as root when using the module.*
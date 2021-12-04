[![CI](https://github.com/ethanbergstrom/Cobalt/actions/workflows/CI.yml/badge.svg)](https://github.com/ethanbergstrom/Cobalt/actions/workflows/CI.yml)

# Cobalt
Cobalt is a simple PowerShell Crescendo wrapper for WinGet

## Requirements
In addition to PowerShell 5.1+ and an Internet connection on a Windows machine, WinGet must also be installed. Microsoft recommends installing WinGet from the Windows Store as part of the [App Installer](https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1?activetab=pivot:overviewtab) package.

## Install Cobalt
```PowerShell
Install-Module Cobalt -Force
```

## Sample usages
### Search for a package
```PowerShell
Find-WinGetPackage -ID openJS.nodejs

Find-WinGetPackage -ID Mozilla.Firefox -Exact
```

### Install a package
```PowerShell
Find-WinGetPackage OpenJS.NodeJS -Exact | Install-WinGetPackage

Install-WinGetPackage 7zip.7zip -Exact
```

### Get list of installed packages
```PowerShell
Get-WinGetPackage nodejs
```

### Uninstall a package
```PowerShell
Get-WinGetPackage nodejs | Uninstall-WinGetPackage
```

### Manage package sources
```PowerShell
Register-WinGetSource privateRepo -Argument 'https://somewhere/out/there/api/v2/'
Find-WinGetPackage nodejs -Source privateRepo -Exact | Install-WinGetPackage
Unregister-WinGetSource privateRepo
```

Cobalt integrates with WinGet.exe to manage and store source information

## Known Issues
### Stability
WinGet's behavior and APIs are still very unstable. Do not be surprised if this module stops working with newer versions of WinGet.

## Legal and Licensing
Cobalt is licensed under the [MIT license](./LICENSE.txt).

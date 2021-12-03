[![CI](https://github.com/ethanbergstrom/Cobalt/actions/workflows/CI.yml/badge.svg)](https://github.com/ethanbergstrom/Cobalt/actions/workflows/CI.yml)

# Cobalt
Cobalt is a PowerShell Crescendo wrapper for WinGet

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
### Garbled Output with Long Package Names
WinGet uses a hard-coded output width of 120 characters if it cant determine console width (like when invoked by a Crescendo module), but doesn't correctly truncate the output, which leaves a mess. See https://github.com/microsoft/winget-cli/issues/1300 for more information. Would not recommend using Cobalt as a means of searching for packages with long package names or IDs.

### Stability
WinGet's behavior and APIs are still very unstable. Do not be surprised if this module stops working with newer versions of WinGet.

## Legal and Licensing
Cobalt is licensed under the [MIT license](./LICENSE.txt).

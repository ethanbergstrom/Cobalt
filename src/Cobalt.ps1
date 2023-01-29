$BaseOriginalName = 'WinGet'

$BaseOriginalCommandElements = @()

$BaseParameters = @()

$BaseOutputHandlers = @{
    ParameterSetName = 'Default'
    Handler = {
        param ( $output )
    }
}

$outputHanderHeader = {param ($output)}

$i18nHandlerHelper = {
    $language = (Get-UICulture).Name

    $languageData = $(
        $hash = @{}

        $(try {
            # We have to trim the leading BOM for .NET's XML parser to correctly read Microsoft's own files - go figure
            ([xml](((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/microsoft/winget-cli/v1.3.2691/Localization/Resources/$language/winget.resw" -ErrorAction Stop ).Content -replace "\uFEFF", ""))).root.data
        } catch {
            # Fall back to English if a locale file doesn't exist
            (
                ('SearchName','Name'),
                ('SearchID','Id'),
                ('SearchVersion','Version'),
                ('AvailableHeader','Available'),
                ('SearchSource','Source'),
                ('ShowVersion','Version'),
                ('GetManifestResultVersionNotFound','No version found matching:'),
                ('InstallerFailedWithCode','Installer failed with exit code:'),
                ('UninstallFailedWithCode','Uninstall failed with exit code:'),
                ('AvailableUpgrades','upgrades available.')
            ) | ForEach-Object {[pscustomobject]@{name = $_[0]; value = $_[1]}}
        }) | ForEach-Object {
            # Convert the array into a hashtable
            $hash[$_.name] = $_.value
        }

        $hash
    )
}

$GetPackageOutputHandler = {
    $nameHeader = $output -Match "^$($languageData.SearchName)"

    if ($nameHeader) {

        $headerLine = $output.IndexOf(($nameHeader | Select-Object -First 1))

        if ($headerLine -ne -1) {
            $idIndex = $output[$headerLine].IndexOf(($languageData.SearchID))
            $versionIndex = $output[$headerLine].IndexOf(($languageData.SearchVersion))
            $availableIndex = $output[$headerLine].IndexOf(($languageData.AvailableHeader))
            $sourceIndex = $output[$headerLine].IndexOf(($languageData.SearchSource))

            # Stop gathering version data at the 'Available' column if it exists, if not continue on to the 'Source' column (if it exists)
            $versionEndIndex = $(
                if ($availableIndex -ne -1) {
                    $availableIndex
                } else {
                    $sourceIndex
                }
            )

            # Only attempt to parse output if it contains a 'version' column
            if ($versionIndex -ne -1) {
                # The -replace cleans up errant characters that come from WinGet's poor treatment of truncated columnar output
                ($output | Select-String -Pattern $languageData.AvailableUpgrades,'--include-unknown' -NotMatch) -replace '[^i\p{IsBasicLatin}]+',' ' | Select-Object -Skip ($headerLine+2) | ForEach-Object {
                    Remove-Variable -Name 'package' -ErrorAction SilentlyContinue

                    $package = [ordered]@{
                        ID = $_.SubString($idIndex,$versionIndex-$idIndex).Trim()
                    }

                    if ($package) {
                        # I'm so sorry, blame WinGet
                        # If neither the 'Available' or 'Source' column exist, gather version data to the end of the string
                        $package.Version = $(
                            if ($versionEndIndex -ne -1) {
                                $_.SubString($versionIndex,$versionEndIndex-$versionIndex)
                            } else {
                                $_.SubString($versionIndex)
                            }
                        ).Trim() -replace '[^\.\d]'

                        # Only attempt to add 'Available Version' data if the column exists
                        if ($availableIndex -ne -1) {
                            $package.Available = $(
                                if ($sourceIndex -ne -1) {
                                    $_.SubString($availableIndex,$sourceIndex-$availableIndex)
                                } else {
                                    $_.SubString($availableIndex)
                                }
                            ).Trim() -replace '[^\.\d]'
                        }

                        # If the 'Source' column was included in the output, include it in our output, too
                        if (($sourceIndex -ne -1) -And ($_.Length -ge $sourceIndex)) {
                            $package.Source = $_.SubString($sourceIndex).Trim() -split ' ' | Select-Object -Last 1
                        }

                        [pscustomobject]$package
                    }
                }
            }
        }
    }
}

$InstallPackageOutputHandler = {
    if ($output) {
        if ($output -match $languageData.InstallerFailedWithCode) {
            # Only show output that matches or comes after the 'failed' keyword
            Write-Error ($output[$output.IndexOf($($output -match $languageData.InstallerFailedWithCode | Select-Object -First 1))..($output.Length-1)] -join "`r`n")
        } else {
            $output | ForEach-Object {
                if ($_ -match 'Found .+ \[(?<id>[\S]+)\] Version (?<version>[\S]+)' -and $Matches.id -and $Matches.version) {
                    [pscustomobject]@{
                        ID = $Matches.id
                        Version = $Matches.version
                    }
                }
            }
        }
    }
}

$UnInstallPackageOutputHandler = {
    if ($output) {
        if ($output -match $languageData.UninstallFailedWithCode) {
            # Only show output that matches or comes after the 'failed' keyword
            Write-Error ($output[$output.IndexOf($($output -match $languageData.UninstallFailedWithCode | Select-Object -First 1))..($output.Length-1)] -join "`r`n")
        }
    }
}

$PackageInfoVersionOutputHandler = {
    if ($output) {
        if ($output | Select-String -Pattern $languageData.GetManifestResultVersionNotFound) {
            # Only show output that matches or comes after the 'failed' keyword
            Write-Error ($output[$output.IndexOf($($output | Select-String -Pattern $languageData.GetManifestResultVersionNotFound | Select-Object -First 1))..($output.Length-1)] -join "`r`n")
        } else {
            $versionHeader = $output -Match "^$($languageData.ShowVersion)"

            if ($versionHeader) {

                $headerLine = $output.IndexOf(($versionHeader | Select-Object -First 1))

                if ($headerLine -ne -1) {
                    $output | Select-Object -Skip ($headerLine+2)
                }
            }
        }
    }
}

$RenderedGetPackageOutputHandler = [scriptblock]::Create($outputHanderHeader.ToString() + $i18nHandlerHelper.ToString() + $GetPackageOutputHandler.ToString())
$RenderedInstallPackageOutputHandler = [scriptblock]::Create($outputHanderHeader.ToString() + $i18nHandlerHelper.ToString() + $InstallPackageOutputHandler.ToString())
$RenderedUnInstallPackageOutputHandler = [scriptblock]::Create($outputHanderHeader.ToString() + $i18nHandlerHelper.ToString() + $UnInstallPackageOutputHandler.ToString())
$RenderedPackageInfoVersionOutputHandler = [scriptblock]::Create($outputHanderHeader.ToString() + $i18nHandlerHelper.ToString() + $PackageInfoVersionOutputHandler.ToString())

# The general structure of this hashtable is to define noun-level attributes, which are -probably- common across all commands for the same noun, but still allow for customization at more specific verb-level defition for that noun.
# The following three command attributes have the following order of precedence:
# 	OriginalCommandElements will be MERGED in the order of Noun + Verb + Base
#		Example: Noun WinGetSource's element 'source', Verb Register's element 'add', and Base elements are merged to become 'WinGet source add --limit-output --yes'
# 	Parameters will be MERGED in the order of Noun + Verb + Base
#		Example: Noun WinGetPackage's parameters for package name and version and Verb Install's parameter specifying source information are merged to become '<packageName> --version=<packageVersion> --source=<packageSource>'.
#			These are then appended to the merged original command elements, to create 'WinGet install <packageName> --version=<packageVersion> --source=<packageSource> --limit-output --yes'
# 	OutputHandler sets will SUPERCEDE each other in the order of: Verb -beats-> Noun -beats-> Base. This allows reusability of PowerShell parsing code.
#		Example: Noun WinGetPackage has inline output handler PowerShell code with complex regex that works for both Install-WinGetPackage and Uninstall-WinGetPackage, but Get-WinGetPackage's native output uses simple vertical bar delimiters.
#		Example 2: The native commands for Register-WinGetSource and Unregister-WinGetSource don't return any output, and until Crescendo supports error handling by exit codes, a base required default output handler that doesn't do anything can be defined and reused in multiple places.
$Commands = @(
    @{
        Noun = 'WinGetSource'
        OriginalCommandElements = @('source')
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Return WinGet package sources'
                OriginalCommandElements = @('export')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Source Name'
                        OriginalName = '--name='
                        NoGap = $true
                    }
                )
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ($output)
                        if ($output) {
                            $output | ConvertFrom-Json
                        }
                    }
                }
            },
            @{
                Verb = 'Register'
                Description = 'Register a new WinGet package source'
                OriginalCommandElements = @('add')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Source Name'
                        OriginalName = '--name='
                        NoGap = $true
                        Mandatory = $true
                    },
                    @{
                        Name = 'Argument'
                        OriginalName = '--arg='
                        ParameterType = 'string'
                        Description = 'Source Argument'
                        NoGap = $true
                        Mandatory = $true
                    }
                )
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ($output)
                        if ($output) {
                            if ($output[-1] -ne 'Done') {
                                Write-Error ($output -join "`r`n")
                            }
                        }
                    }
                }
            },
            @{
                Verb = 'Unregister'
                Description = 'Unegister an existing WinGet package source'
                OriginalCommandElements = @('remove')
                Parameters = @(
                    @{
                        Name = 'Name'
                        ParameterType = 'string'
                        Description = 'Source Name'
                        OriginalName = '--name='
                        NoGap = $true
                        Mandatory = $true
                        ValueFromPipelineByPropertyName = $true
                    }
                )
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = {
                        param ($output)
                        if ($output) {
                            if ($output[-1] -match 'Did not find a source') {
                                Write-Error ($output -join "`r`n")
                            }
                        }
                    }
                }
            }
        )
    },
    @{
        Noun = 'WinGetPackage'
        Parameters = @(
            @{
                Name = 'ID'
                OriginalName = '--id='
                ParameterType = 'string'
                Description = 'Package ID'
                NoGap = $true
                ValueFromPipelineByPropertyName = $true
            },
            @{
                Name = 'Exact'
                OriginalName = '--exact'
                ParameterType = 'switch'
                Description = 'Search by exact package name'
            },
            @{
                Name = 'Source'
                OriginalName = '--source='
                ParameterType = 'string'
                Description = 'Package Source'
                NoGap = $true
                ValueFromPipelineByPropertyName = $true
            }
        )
        OutputHandlers = @{
            ParameterSetName = 'Default'
            Handler = $RenderedGetPackageOutputHandler
        }
        Verbs = @(
            @{
                Verb = 'Install'
                Description = 'Install a new package with WinGet'
                OriginalCommandElements = @('install','--accept-package-agreements','--accept-source-agreements','--silent')
                Parameters = @(
                    @{
                        Name = 'Version'
                        OriginalName = '--version='
                        ParameterType = 'string'
                        Description = 'Package Version'
                        NoGap = $true
                        ValueFromPipelineByPropertyName = $true
                    }
                )
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = $RenderedInstallPackageOutputHandler
                }
            },
            @{
                Verb = 'Get'
                Description = 'Get a list of installed WinGet packages'
                OriginalCommandElements = @('list','--accept-source-agreements')
            },
            @{
                Verb = 'Find'
                Description = 'Find a list of available WinGet packages'
                OriginalCommandElements = @('search','--accept-source-agreements')
            },
            @{
                Verb = 'Update'
                Description = 'Updates an installed package to the latest version'
                OriginalCommandElements = @('upgrade','--accept-source-agreements','--silent')
                Parameters = @(
                    @{
                        Name = 'All'
                        OriginalName = '--all'
                        ParameterType = 'switch'
                        Description = 'Upgrade all packages'
                    }
                )
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = $RenderedInstallPackageOutputHandler
                }
            },
            @{
                Verb = 'Uninstall'
                Description = 'Uninstall an existing package with WinGet'
                OriginalCommandElements = @('uninstall','--accept-source-agreements','--silent')
                OutputHandlers = @{
                    ParameterSetName = 'Default'
                    Handler = $RenderedUnInstallPackageOutputHandler
                }
            }
        )
    },
    @{
        Noun = 'WinGetPackageInfo'
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Shows information on a specific WinGet package'
                OriginalCommandElements = @('show','--accept-source-agreements')
                DefaultParameterSetName = 'Default'
                Parameters = @(
                    @{
                        Name = 'ID'
                        OriginalName = '--id='
                        ParameterType = 'string'
                        Description = 'Package ID'
                        NoGap = $true
                        Mandatory = $true
                        ValueFromPipelineByPropertyName = $true
                        Position = 0
                        ParameterSetName = @('Default','Versions')
                    },
                    @{
                        Name = 'Exact'
                        OriginalName = '--exact'
                        ParameterType = 'switch'
                        Description = 'Search by exact package name'
                        ParameterSetName = @('Default','Versions')
                    },
                    @{
                        Name = 'Version'
                        OriginalName = '--version='
                        ParameterType = 'string'
                        Description = 'Package Version'
                        NoGap = $true
                        ValueFromPipelineByPropertyName = $true
                        ParameterSetName = @('Default','Versions')
                    },
                    @{
                        Name = 'Source'
                        OriginalName = '--source='
                        ParameterType = 'string'
                        Description = 'Package Source'
                        NoGap = $true
                        ValueFromPipelineByPropertyName = $true
                        ParameterSetName = @('Default','Versions')
                    },
                    @{
                        Name = 'Versions'
                        OriginalName = '--versions'
                        ParameterType = 'switch'
                        Description = 'Show available versions of the package'
                        ParameterSetName = 'Versions'
                    }
                )
                OutputHandlers = @(
                    @{
                        ParameterSetName = 'Default'
                        Handler = {
                            param ( $output )

                            $packageInfo = @{}

                            $output | Select-String -AllMatches -Pattern '^\s*([\w\s]+):\s(.+)$' | ForEach-Object -MemberName Matches | ForEach-Object{
                                $match = ($_.Groups | Select-Object -Skip 1).Value
                                $packageInfo.add($match[0],$match[1])
                            }

                            $packageInfo
                        }
                    },
                    @{
                        ParameterSetName = 'Versions'
                        Handler = $RenderedPackageInfoVersionOutputHandler
                    }
                )
            }
        )
    },
    @{
        Noun = 'WinGetPackageUpdate'
        OutputHandlers = @{
            ParameterSetName = 'Default'
            Handler = $RenderedGetPackageOutputHandler
        }
        Verbs = @(
            @{
                Verb = 'Get'
                Description = 'Get a list of installed WinGet packages'
                # Add this back in after WinGet 1.3 is released
                # https://github.com/microsoft/winget-cli/issues/1869
                # https://github.com/microsoft/winget-cli/pull/1874
                # OriginalCommandElements = @('upgrade','--accept-source-agreements')
                OriginalCommandElements = @('upgrade')
            }
        )
    }
)

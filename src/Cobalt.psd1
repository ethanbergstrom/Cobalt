@{
	RootModule = 'Cobalt.psm1'
	ModuleVersion = '0.1.0'
	GUID = '9f295092-e7fd-4c52-b41e-3c5b0612fa52'
	Author = 'Ethan Bergstrom'
	Copyright = '2021'
	Description = 'A PowerShell Crescendo wrapper for WinGet'
	# Crescendo modules aren't supported below PowerShell 5.1
	# https://devblogs.microsoft.com/powershell/announcing-powershell-crescendo-preview-1/
	PowerShellVersion = '5.1'
	PrivateData = @{
		PSData = @{
			# Tags applied to this module to indicate this is a PackageManagement Provider.
			Tags = @('Crescendo','WinGet','PSEdition_Desktop','PSEdition_Core','Windows','CrescendoBuilt')

			# A URL to the license for this module.
			LicenseUri = 'https://github.com/ethanbergstrom/Cobalt/blob/main/LICENSE.txt'

			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/ethanbergstrom/Cobalt'
		}
	}
}

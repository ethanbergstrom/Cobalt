Import-Module Cobalt

Describe 'basic package search operations' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'Microsoft.PowerShell'
		}

		It 'gets a list of latest installed packages' {
			Get-WinGetPackage | Where-Object {$_.Source -eq 'winget'} | Should -Not -BeNullOrEmpty
		}
		It 'searches for the latest version of a package' {
			Find-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe 'DSC-compliant package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'CPUID.CPU-Z'
		}

		It 'searches for the latest version of a package' {
			Find-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently installs the latest version of a package' {
			Install-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds the locally installed package just installed' {
			Get-WinGetPackage -ID $package | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'silently uninstalls the locally installed package just installed' {
			{Uninstall-WinGetPackage -ID $package} | Should -Not -Throw
		}
	}
}

Describe 'pipline-based package installation and uninstallation' {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'CPUID.CPU-Z'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-WinGetPackage -ID $package -Exact | Install-WinGetPackage | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-WinGetPackage -ID $package | Uninstall-WinGetPackage} | Should -Not -Throw
		}
	}
}

Describe 'package version handling' {
	Context 'a long package name' {
		BeforeAll {
			# Winget columnar output introduces strange characters in termainal output when package name exceeds 41 characters.
			# The full name of this package in Winget is 'Microsoft Visual C++ 2013 Redistributable (x64)', which is 47 characters and is already installed on GitHub Action's runners by default
			# https://github.com/actions/runner-images/blob/main/images/win/Windows2022-Readme.md#microsoft-visual-c
			$package = 'Microsoft.VCRedist.2013.x64'
			# VC2013 packages are always numbered 12.x
			$majorVersion = 12
		}

		It 'recognizes a package upgrade is available' {
			Get-WinGetPackageUpdate $package | Where-Object {([version]$_.Version).Major -eq $majorVersion} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe 'package upgrade' {
	Context 'a single package' {
		BeforeAll {
			$package = 'CPUID.CPU-Z'
			$version = '1.95'
			Install-WinGetPackage -ID $package -Version $version -Exact
		}
		AfterAll {
			Uninstall-WinGetPackage -ID $package
		}

		It 'recognizes a package upgrade is available' {
			Get-WinGetPackageUpdate | Where-Object {$_.ID -eq $package} | Where-Object {[version]$_.available -gt [version]$version} | Should -Not -BeNullOrEmpty
		}
		It 'upgrades a specific package to the latest version' {
			Update-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -Not -BeNullOrEmpty
		}
		It 'upgrades again, and returns no output, because everything is up to date' {
			Update-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -BeNullOrEmpty
		}
	}
}

Describe 'WinGet error handling' {
	Context 'no results returned' {
		BeforeAll {
			$package = 'Cisco.*'
		}

		It 'searches for an ID that will never exist' {
			{Find-WinGetPackage -ID $package} | Should -Not -Throw
		}
		It 'searches for an ID that will never exist' {
			{Get-WinGetPackage -ID $package} | Should -Not -Throw
		}
	}
}

Describe 'package metadata retrieval' {
	Context 'package details' {
		BeforeAll {
			$package = 'Mozilla.Firefox'
			$version = '98.0'
		}

		It 'returns package metadata' {
			Get-WinGetPackageInfo -ID $package -Version $version -Exact | Where-Object {$_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
		It 'returns package versions' {
			(Get-WinGetPackageInfo -ID $package -Versions -Exact).Contains($version) | Should -Be $true
		}
	}
}

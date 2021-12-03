Import-Module Cobalt

Describe "basic package search operations" {
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

Describe "DSC-compliant package installation and uninstallation" {
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

Describe "pipline-based package installation and uninstallation" {
	Context 'without additional arguments' {
		BeforeAll {
			$package = 'CPUID.CPU-Z'
		}

		It 'searches for and silently installs the latest version of a package' {
			Find-WinGetPackage -ID $package | Install-WinGetPackage | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-WinGetPackage -ID $package -Exact | Uninstall-WinGetPackage} | Should -Not -Throw
		}
	}
}

Describe "version filters" {
	BeforeAll {
		$package = 'ninja'
		# Keep at least one version back, to test the 'latest' feature
		$version = '1.10.1'
	}
	AfterAll {
		Uninstall-WinGetPackage -Name $package -ErrorAction SilentlyContinue
	}

	Context 'required version' {
		It 'searches for and silently installs a specific package version' {
			Get-WinGetPackage -Name $package -Version $version -Exact | Install-WinGetPackage -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls a specific package version' {
			Get-WinGetPackage -Name $package -Version $version -LocalOnly | UnInstall-WinGetPackage -Force | Where-Object {$_.Name -contains $package -and $_.Version -eq $version} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "error handling on WinGet failures" {
	Context 'package installation' {
		BeforeAll {
			$package = 'googlechrome'
			# This version is known to be broken, per https://github.com/WinGet-community/WinGet-coreteampackages/issues/1608
			$version = '87.0.4280.141'
		}
		AfterAll {
			Uninstall-WinGetPackage -Name $package -ErrorAction SilentlyContinue
		}

		It 'searches for and fails to silently install a broken package version' {
			{Get-WinGetPackage -Name $package -Version $version -Exact | Install-WinGetPackage -Force} | Should -Throw
		}
	}
	Context 'package uninstallation' {
		BeforeAll {
			$package = 'chromium'
			# This version is known to be broken, per https://github.com/WinGet-community/WinGet-coreteampackages/issues/341
			$version = '56.0.2897.0'
		}

		It 'searches for, installs, and fails to silently uninstall a broken package version' {
			{Get-WinGetPackage -Name $package -Version $version -Exact | Install-WinGetPackage -Force | Uninstall-WinGetPackage} | Should -Throw
		}
	}
}

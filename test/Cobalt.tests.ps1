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
			Find-WinGetPackage -ID $package -Exact | Install-WinGetPackage | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}
		It 'finds and silently uninstalls the locally installed package just installed' {
			{Get-WinGetPackage -ID $package | Uninstall-WinGetPackage} | Should -Not -Throw
		}
	}
}

Describe "package upgrade" {
	Context 'a single package' {
		BeforeAll {
			$package = 'CPUID.CPU-Z'
			$version = '1.95'
			Install-WinGetPackage -ID $package -Version $version -Exact
		}
		AfterAll {
			Uninstall-WinGetPackage -ID $package
		}

		It 'upgrade a specific package to the latest version' {
			Update-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -Not -BeNullOrEmpty
		}
	}
	Context 'multiple packages' {
		BeforeAll {
			$packages = @(
				@{
					id = 'CPUID.CPU-Z'
					version = '1.95'
				},
				@{
					id = 'vim.vim'
					version = '8.2.3821'
				}
			)
			$packages | ForEach-Object {Install-WinGetPackage -ID $_.id -Version $_.version -Exact}
		}

		It 'upgrades all packages without erroring' {
			{Update-WinGetPackage -All} Should -Not -Throw | Where-Object {$_.ID -eq $package} | Should -Not -BeNullOrEmpty
		}

		It 'successfully upgraded CPU-Z a newer version' {
			$packages | Where-Object id -eq 'CPUID.CPU-Z' | ForEach-Object {
				$package = $_
				Get-WinGetPackage -ID $package.id | Where-Object {[version]$_.version -gt [version]$package.version}
			} | Should -Not -BeNullOrEmpty
		}

		It 'successfully upgraded vim a newer version' {
			$packages | Where-Object id -eq 'vim.vim' | ForEach-Object {
				$package = $_
				Get-WinGetPackage -ID $package.id | Where-Object {[version]$_.version -gt [version]$package.version}
			} | Should -Not -BeNullOrEmpty
		}
	}
}

Describe "WinGet error handling" {
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

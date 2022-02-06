﻿Import-Module Cobalt

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

		It 'upgrades a specific package to the latest version' {
			Update-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -Not -BeNullOrEmpty
		}
		It 'upgrades again, and returns no output, because everything is up to date' {
			Update-WinGetPackage -ID $package -Exact | Where-Object {$_.ID -eq $package} | Where-Object {[version]$_.version -gt [version]$version} | Should -BeNullOrEmpty
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
					id = 'putty.putty'
					version = '0.74'
				}
			)
			$packages | ForEach-Object {Install-WinGetPackage -ID $_.id -Version $_.version -Exact}
		}
		AfterAll {
			$packages | ForEach-Object {Uninstall-WinGetPackage -ID $_.id}
		}

		It 'upgrades all packages without erroring' {
			Update-WinGetPackage -All | Should -Not -BeNullOrEmpty
		}

		It 'successfully upgraded packages to a newer version' {
			$packages | ForEach-Object {
				$package = $_
				Get-WinGetPackage -ID $package.id | Where-Object {[version]$_.version -gt [version]$package.version} | Should -Not -BeNullOrEmpty
			}
		}

		It 'upgrades all packages again, and returns no output, because everything is up to date' {
			Update-WinGetPackage -All | Should -BeNullOrEmpty
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

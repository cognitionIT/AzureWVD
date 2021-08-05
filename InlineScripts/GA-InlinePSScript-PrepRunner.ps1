# Create the Bicep install folder
$installPath = "$env:USERPROFILE\.bicep"
$installDir = New-Item -ItemType Directory -Path $installPath -Force
$installDir.Attributes += 'Hidden'

# Fetch the latest Bicep CLI binary
(New-Object Net.WebClient).DownloadFile("https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe", "$installPath\bicep.exe")

# Add bicep to your PATH
$currentPath = (Get-Item -path "HKCU:\Environment" ).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
if (-not $currentPath.Contains("%USERPROFILE%\.bicep")) { setx PATH ($currentPath + ";%USERPROFILE%\.bicep") }
if (-not $env:path.Contains($installPath)) { $env:path += ";$installPath" }

# Copy the bicep file to %systemroot%\system32 if it is not already there
if (-not(Test-Path "$($env:SystemRoot)\System32\bicep.exe"))
{
  Copy-Item "$installPath\bicep.exe" -Destination "$($env:SystemRoot)\System32" -Force
}

# Verify you can now access the 'bicep' command.
bicep --help
# Done!

## Add Az PowerShell Module version 5.6.0+ to the runner (if not already on the runner)
$minAzModuleVersion = '5.6.0'
if(!(Test-Path "C:\Modules\az_$minAzModuleVersion")) {
  Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
  Save-Module -Path "C:\Modules\az_$minAzModuleVersion" -Name Az -RequiredVersion $minAzModuleVersion -Force -ErrorAction Stop
}
$env:PSModulePath = "C:\Modules\az_$($minAzModuleVersion);$($env:PSModulePath)"
# Check installed versions of Az Module
Get-InstalledModule -Name Az -AllVersions | Sort Version -Descending

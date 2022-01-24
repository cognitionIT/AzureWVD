<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder
.NOTES
    Author: Esther Barthel, MSc
    Version: 0.1
    Created: 2020-11-26
    Updated: 2022-01-23 - added vscode and installation of extensions

    Research Links: 
#>

#region Create Temporary Installation folder (for downloaded resources)
New-Item -Path 'C:\Install' -ItemType Directory -Force | Out-Null
#endregion

#region Install Notepad++
Invoke-WebRequest -Uri 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.1/npp.7.9.1.Installer.exe' -OutFile 'c:\Install\npp.7.9.1.Installer.exe'
Invoke-Expression -Command 'C:\Install\npp.7.9.1.Installer.exe /S'

# Wait for Notepad++ installer to finish
Start-Sleep -Seconds 10
#endregion

#region Install Acrobat Reader DC
#Invoke-WebRequest -Uri 'ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/2001320064/AcroRdrDC2001320064_en_US.exe' -OutFile 'c:\Install\AcroRdrDC2001320064_en_US.exe'
#Invoke-Expression -Command 'C:\Install\AcroRdrDC2001320064_en_US.exe /sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES'
#Start-Process -FilePath "C:\Install\AcroRdrDC2001320064_en_US.exe" -ArgumentList "/sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES" #-Wait

# Wait for Adobe Installer to finish
#Start-Sleep -Seconds 180
#endregion

#region Install Visual Studio Code
Invoke-WebRequest -Uri 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user' -OutFile 'c:\Install\vscode-install.exe'
Invoke-Expression -Command 'C:\Install\vscode-install.exe /verysilent /suppressmsgboxes /mergetasks=!runcode'

# Wait for Visual Studio Code installer to finish
Start-Sleep -Seconds 180
#endregion

#region Install Bicep vscode extension
# Install the .NET Install Tool for Extension Authors dependecy for Bicep extension
Invoke-Expression -Command 'code --install-extension ms-dotnettools.vscode-dotnet-runtime --force' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 180
# Install the Bicep extension
Invoke-Expression -Command 'code --install-extension ms-azuretools.vscode-bicep --force' -ErrorAction SilentlyContinue
Start-Sleep -Seconds 180
#endregion

#region Install PowerShell Az module
Install-PackageProvider -Name NuGet -Force
Install-Module -Name Az -Force -Scope AllUsers -Confirm:$false
Get-InstalledModule -Name Az
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force
#endregion

#region install Bicep
# Create the Bicep install folder
$installPath = "C:\Tools\.bicep"
$installDir = New-Item -ItemType Directory -Path $installPath -Force
$installDir.Attributes += 'Hidden'

# Fetch the latest Bicep CLI binary
(New-Object Net.WebClient).DownloadFile("https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe", "$installPath\bicep.exe")

# Add bicep to your PATH
$currentPath = (Get-Item -path "HKCU:\Environment" ).GetValue('Path', '', 'DoNotExpandEnvironmentNames')
if (-not $currentPath.Contains("$($installPath)")) { setx PATH ($currentPath + ";$($installPath)") }
if (-not $env:path.Contains($installPath)) { $env:path += ";$installPath" }

# Copy the bicep file to %systemroot%\system32 if it is not already there
if (-not(Test-Path "$($env:SystemRoot)\System32\bicep.exe"))
{
    Copy-Item "$installPath\bicep.exe" -Destination "$($env:SystemRoot)\System32" -Force
}

# Verify you can now access the 'bicep' command.
#bicep --help
bicep --version
# Done!
#endregion


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
Invoke-WebRequest -Uri 'ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/2001320064/AcroRdrDC2001320064_en_US.exe' -OutFile 'c:\Install\AcroRdrDC2001320064_en_US.exe'
Invoke-Expression -Command 'C:\Install\AcroRdrDC2001320064_en_US.exe /sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES'
#Start-Process -FilePath "C:\Install\AcroRdrDC2001320064_en_US.exe" -ArgumentList "/sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES" #-Wait

# Wait for Adobe Installer to finish
Start-Sleep -Seconds 180
#endregion

#region Install Visual Studio Code
# Download URL, you may need to update this if it changes
$downloadUrl = "https://go.microsoft.com/fwlink/?LinkID=623230"

# What to name the file and where to put it
$installerFile = "vscode-install.exe"
$installerPath = (Join-Path $env:TEMP $installerFile)

# Install Options
# Reference:
# http://stackoverflow.com/questions/42582230/how-to-install-visual-studio-code-silently-without-auto-open-when-installation
# http://www.jrsoftware.org/ishelp/
# I'm using /silent, use /verysilent for no UI

# Install with the context menu, file association, and add to path options (and don't run code after install: 
$installerArguments = "/silent /mergetasks='!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath'"

#Install with default options, and don't run code after install.
#$installerArguments = "/silent /mergetasks='!runcode'"

Write-Verbose "Downloading $installerFile..."
Invoke-Webrequest $downloadUrl -UseBasicParsing -OutFile $installerPath

Write-Verbose "Installing $installerPath..."
Start-Process $installerPath -ArgumentList $installerArguments -Wait

Write-Verbose "Cleanup the downloaded file."
Remove-Item $installerPath -Force
# Wait for Visual Studio Code installer to finish
Start-Sleep -Seconds 10
#endregion

#region Install Bicep vscode extension
# Install the .NET Install Tool for Extension Authors dependecy for Bicep extension
code --install-extension ms-dotnettools.vscode-dotnet-runtime --force
Start-Sleep -Seconds 10
# Install the Bicep extension
code --install-extension ms-azuretools.vscode-bicep --force
Start-Sleep -Seconds 10
#endregion

#region Install PowerShell Az module
Install-Module -Name Az -Force -Scope AllUsers
#endregion


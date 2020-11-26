<#
.Synopsis
    Customization script for Azure Image Builder
.DESCRIPTION
    Customization script for Azure Image Builder
.NOTES
    Author: Esther Barthel, MSc
    Version: 0.1
    Created: 2020-11-26
    Updated: 2020-11-26 - 

    Research Links: 
#>

# Create Temporary Installation folder (for downloaded resources)
New-Item -Path 'C:\Install' -ItemType Directory -Force | Out-Null

# Install Notepad++
Invoke-WebRequest -Uri 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.1/npp.7.9.1.Installer.exe' -OutFile 'c:\Install\notepadppinstaller.exe'
Invoke-Expression -Command 'c:\Install\notepadppinstaller.exe /S'

# Wait
Start-Sleep -Seconds 10


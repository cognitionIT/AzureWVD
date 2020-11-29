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
Invoke-WebRequest -Uri 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.1/npp.7.9.1.Installer.exe' -OutFile 'c:\Install\npp.7.9.1.Installer.exe'
Invoke-Expression -Command 'c:\Install\npp.7.9.1.Installer.exe /S'

# Wait for Notepad++ installer to finish
Start-Sleep -Seconds 10

# Install Acrobat Reader DC
Invoke-WebRequest -Uri 'ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/2001320064/AcroRdrDC2001320064_en_US.exe' -OutFile 'c:\Install\AcroRdrDC2001320064_en_US.exe'
Start-Process -FilePath "c:\Install\AcroRdrDC2001320064_en_US.exe" -ArgumentList "/sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES" -Wait

# Wait for Adobe Installer to finish
Start-Sleep -Seconds 10

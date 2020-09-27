<#
.SYNOPSIS
    Get WVD Remote App Application Group Applications information, sorted by Name.
.DESCRIPTION
    Get WVD Remote App Application Group Applications information, using REST API calls.
.EXAMPLE
    Get-WVDApplicationGroupApplication -ResourceGroupName <string> -ApplicationGroupName <string>
.EXAMPLE
    Get-WVDApplicationGroupApplication  -ResourceGroupName <string> -ApplicationGroupName <string> -ApplicationName <string>
.CONTEXT
    Windows Virtual Desktops
.NOTES
    Version:        0.1
    Author:         Esther Barthel, MSc
    Creation Date:  2020-08-24
    Updated:        2020-08-24

    Purpose:        WVD Administration, through REST API calls
        
    Copyright (c) cognition IT. All rights reserved.
#>
[CmdletBinding()]
Param
(
    [Parameter(
        Position=0, 
        Mandatory=$true, 
        HelpMessage='Enter a Resource Group Name'
    )]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    [Parameter(
        Position=1, 
        Mandatory=$true, 
        HelpMessage='Enter the Application Group Name'
    )]
    [ValidateNotNullOrEmpty()]
    [string] $ApplicationGroupName,

    [Parameter(
        Position=2, 
        Mandatory=$false, 
        HelpMessage='Enter a Application Name (wildcards allowed)'
    )]
    [ValidateNotNullOrEmpty()]
    [string] $ApplicationName
)    

# dot sourcing WVD Functions
. ".\WVDFunctionsREST.ps1"

#-----------------#
# Script Workflow #
#-----------------#
Write-Host ""

#region Retrieve input parameters
If ([string]::IsNullOrEmpty($ApplicationName))
{
    $ApplicationName = "*"
}
#endregion

If ($azSPCredentials = Get-AzSPStoredCredentials)
{
    #debug: $azSPCredentials
    # Sign in to Azure with a Service Principal with Contributor Role at Subscription level and retrieve a brearer token
    try
    {
        $azBearerToken = $null
        $azBearerToken = Get-AzBearerToken -SPCredentials $azSPCredentials.spCreds -TenantID $($azSPCredentials.tenantID).ToString()
        #debug: $azBearerToken
    }
    catch
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
        Exit
    }

    # Retrieve the Subscription information for the Service Principal (that is logged on)
    $azSubscription = $null
    $azSubscription = Get-AzSubscription -bearerToken $($azBearerToken.access_token)
    #debug: Write-Output "DEBUG INFO - subscriptionID: $($azSubscription.subscriptionId)"

    # Retrieve the WVD Application details
    $applicationResults = Get-WVDApplicationGroupApplication -bearerToken $($azBearerToken.access_token) -SubscriptionID $($azSubscription.subscriptionId) -ResourceGroupName $ResourceGroupName -ApplicationGroupName $ApplicationGroupName -ApplicationName $ApplicationName
    #debug: $applicationResults | Format-List

    # Present the information
    foreach ($application in $applicationResults)
    {
        Write-host "application $($application.name.Split("/")[1]) details: " -ForegroundColor Yellow
        $application | Select @{Name='ID'; Expression={$_.id}}, 
            @{Name='Name'; Expression={$_.name}}, 
            @{Name='Application Name'; Expression={$_.name.Split("/")[1]}}, 
            @{Name='Type'; Expression={$_.type}}, 
            @{Name='Description'; Expression={$_.properties.description}}, 
            @{Name='Friendly Name'; Expression={$_.properties.friendlyName}}, 
            @{Name='File Path'; Expression={$_.properties.filePath}}, 
            @{Name='Commandline Setting'; Expression={$_.properties.commandlineSetting}}, 
            @{Name='Commandline Arguments'; Expression={$_.properties.commandlineArguments}}, 
            @{Name='Show in portal'; Expression={$_.properties.showInPortal}}, 
            @{Name='Icon Path'; Expression={$_.properties.iconPath}}, 
            @{Name='Icon Index'; Expression={$_.properties.iconIndex}}, 
            #@{Name='Icon Hash'; Expression={$_.properties.iconHash}}, 
            @{Name='Resource Group'; Expression={$_.id.Split("/")[4]}}, 
            @{Name='Application Group'; Expression={$_.id.Split("/")[8]}} 
    }    
}
else 
{
    Write-Warning "No Azure Credentials could be retrieved from the stored credentials file for this user."
}

# SIG # Begin signature block
# MIINHAYJKoZIhvcNAQcCoIINDTCCDQkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJExUx3nrrcwnVv9yvf/b6hiE
# yzOgggpeMIIFJjCCBA6gAwIBAgIQCyXBE0rAWScxh3bGfykLTjANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMDgxMDAwMDAwMFoXDTIzMDgx
# NTEyMDAwMFowYzELMAkGA1UEBhMCTkwxDzANBgNVBAcTBkxlbW1lcjEVMBMGA1UE
# ChMMY29nbml0aW9uIElUMRUwEwYDVQQLEwxDb2RlIFNpZ25pbmcxFTATBgNVBAMT
# DGNvZ25pdGlvbiBJVDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL2y
# YRbztz9wTtatpSJ5NMD0JZtDPhuFqAVTjoGc1jvn68M41zlGgi8fVvEccaH3nDTT
# 6T8edgFuEbsZVHZGmY109zHOPwXX+Zvp3T+Hk2Ys8Liwwirr6xw9dlneBu85j8gd
# Mamz+mNjzpyBg1eVlD7cV1JAL3oAXgONRiebdpD6DPvd3melPmeg84Un3VV6+W8M
# 8Y0Pec+TbxIda18Lr4DqnIl0a/Suk8kQ2DzZXDXoK+MCfA6zsqyEOSY5yI5OwdU0
# 93LC2PHFEKEkIogBlCiD0UQDbamPdu7wZnTAHPTDfifdMhCPLBA0y4pj4jm6ggFE
# 3ZuQMR/yU8JXSwy72ZECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl
# 6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBR2SeoVDh3RxGqV5iamn/FFU6J65zAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOg
# MYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEW
# HGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEF
# BQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBO
# BggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJ
# KoZIhvcNAQELBQADggEBAL4Zda674x5WLL8B059a9cxnUIC05LcjD/3hkCLZgbMa
# krDrfsjNpA+KpMiTv2TW5pDRCXGJirJO27XRTojr2F8+gJAyIB+8ZLiyKmy3IcCV
# DXjjb6i/4TiGbDmGL3Ctl5pmWRpksnr3TKSMyxz2OogLS6w9pgRdA1hgJSfZMV+a
# KRrd4iW5YWKIwFZlYDeQqpBBtQ6ujzgQ/04FcmjyOlNch4hofJVLauzkSb1Tnzt1
# 6TyT2pJ9BzasoOlxYEFhn0ikXndlKVBb7gpFInqSf5DJtaVRIXojj0eqN6LZroUz
# 62m2YeR29uC06xcdF7fjo+YKxe+kdApdPfX0Nx9Moc8wggUwMIIEGKADAgECAhAE
# CRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# JDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIx
# MjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMT
# KERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmx
# OttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfT
# xvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6Ygs
# IJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tK
# tel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0
# xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGj
# ggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYD
# VR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCG
# SAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
# L0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1Dlgw
# HwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQAD
# ggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBV
# N7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEb
# Bw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZ
# cbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRr
# sutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKU
# GIUukpHqaGxEMrJmoecYpJpkUe8xggIoMIICJAIBATCBhjByMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWdu
# aW5nIENBAhALJcETSsBZJzGHdsZ/KQtOMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3
# AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBToNtHy54ba
# Jj2GKAeeIkb4B97kGjANBgkqhkiG9w0BAQEFAASCAQCgF2N7RxmfHvQjCylgQl6j
# OnjqTPWBWi02LuV5j+wyDLM9Rn+viaX2B3agDzmFYMvzoUrDfzZYkU8RhwfJiUyc
# UEZB5BBUwc5X5R1lnuJ7DpPflOg+UlLIL4p25Ibno4uG8oR92tSsbX4718RJExOR
# mpOM781ihmRog2mC0HkN+ngWWEuHpmKhV+oYsfsUvtk3y/E5CeTcCGlFIgNA5kqp
# e6+vpafVhwWdgoqDMK68StzIolQm809q11TuGpoJcpAxbphbN8nz/lXTLakphaU5
# nD6P2JI4UvmP4iUfc6ImHBYPuoZG1RZKAh9pi3vWXBxF+tY64JoQbDvGT8jS2m3h
# SIG # End signature block

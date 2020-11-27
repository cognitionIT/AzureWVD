<#
.SYNOPSIS
    Create a WVD Hostpool based on an ARM template.
.DESCRIPTION
    Create a WVD Hostpool based on an ARM template, using the new Az.Desktopvirtualization PowerShell Module and WVD ARM Architecture (2020 Spring Release).
.EXAMPLE
    Invoke-WVDARMCreateHostpool
.LINK
    https://docs.microsoft.com/en-us/azure/virtual-desktop/create-host-pools-powershell
.COMPONENT
    Set-AzSPCredentials - The required Azure Service Principal (Subcription level) and tenantID information need to be securely stored in a Credentials File. The Set-AzSPCredentials Script Action will ensure the file is created according to ControlUp standards
    Az.Desktopvirtualization PowerShell Module - The Az.Desktopvirtualization PowerShell Module must be installed on the machine running this Script Action
.NOTES
    Version:        0.1
    Author:         Esther Barthel, MSc
    Creation Date:  2020-06-21
    Updated:        2020-06-21
                    Changed the script to support WVD 2020 Spring Release (ARM Architecture update)
    Purpose:        Script Action, created for ControlUp WVD Monitoring
        
    Copyright (c) cognition IT. All rights reserved.
#>
[CmdletBinding()]
Param
(
) 

# dot sourcing WVD Functions
. ".\WVDFunctions.ps1"

#------------------------#
# Script Action Workflow #
#------------------------#
Write-Host ""

## Check if the required PowerShell Modules are installed and can be imported
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Accounts" #-Verbose                  # Module for AzureAD
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.DesktopVirtualization" #-Verbose     # Module for WVD
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Resources" #-Verbose                 # Module for ARM Deployments
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Compute" #-Verbose                   # Module for Compute (VirtualMachines)
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.KeyVault" #-Verbose                  # Module for KeyVaults

If (Invoke-NETFrameworkCheck)
{
    If ($azSPCredentials = Get-AzSPStoredCredentials)
    {
        # Sign in to Azure with a Service Principal with Contributor Role at Subscription level
        try
        {
            $azSPSession = Connect-AzAccount -Credential $azSPCredentials.spCreds -Tenant $($azSPCredentials.tenantID).ToString() -ServicePrincipal -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
            Exit
        }

        # Retrieve sensitive information from KeyVault
        $secureAdminPassword = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainadminpassword).SecretValue
        $secureDomainAdminUser = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainadminuser).SecretValue
        $secureDomainName = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainname).SecretValue
        $secureOuPath = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainoupath).SecretValue
        
        # Convert SecureString to Plaintext
        $domainAdminUser = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureDomainAdminUser)))
        $domainName = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureDomainName)))
        $ouPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureOuPath)))

        # Retrieve the Subscription information for the Service Principal (that is logged on)
        $azSubscriptions = Get-AzSubscription

        $postFix = "wvd-sig"

        ## Create a Template Parameter Object (hashtable)
        $objTemplateParameter = @{
            "hostpoolName" = "hp-$($postFix)";
            "hostpoolDescription" = "Created by PowerShell and ARM Template";
            "location" = "eastus";
            "workSpaceName" = "ws-$($postFix)";
            "workspaceLocation" = "eastus";
            "workspaceResourceGroup" = "rg-wvd-infra";
            "allApplicationGroupReferences" = "/subscriptions/$($azSubscriptions.Id)/resourcegroups/rg-wvd-infra/providers/Microsoft.DesktopVirtualization/applicationgroups/hp-$($postFix)-DAG";
            "addToWorkspace" = $true;
            "createAvailabilitySet" = $true;
            "vmResourceGroup" = "rg-wvd-resources";
            "vmLocation" = "westeurope";
            "vmSize" = "Standard_D2s_v3";
            "vmNumberOfInstances" = 1;
            "vmNamePrefix" = "sh-$($postFix)";
            "vmImageType" = "CustomImage";
            "vmCustomImageSourceId" = "/subscriptions/$($azSubscriptions.Id)/resourceGroups/rg-wvd-images/providers/Microsoft.Compute/galleries/sigWVDImages/images/Win10-MU-ImgDef";
            #"vmImageType" = "Gallery";
            #"vmGalleryImageOffer" = "office-365";
            #"vmGalleryImagePublisher" = "MicrosoftWindowsDesktop";
            #"vmGalleryImageSKU" = "19h2-evd-o365pp";
            "vmDiskType" = "StandardSSD_LRS";
            "vmUseManagedDisks" = $true;
            "existingVnetName" = "vnet-wvd-resources";
            "existingSubnetName" = "default";
            "virtualNetworkResourceGroupName" = "rg-wvd-resources";
            "usePublicIP" = $false;
            "createNetworkSecurityGroup" = $false;
            "hostpoolType" = "Pooled";
            "maxSessionLimit" = 25;
            "loadBalancerType" = "BreadthFirst";
            "vmTemplate" = "{`"domain`"`:`"$($domainName)`",`"galleryImageOffer`"`:null,`"galleryImagePublisher`"`:null,`"galleryImageSKU`"`:null,`"imageType`"`:`"CustomImage`",`"imageUri`"`:null,`"customImageId`"`:`"/subscriptions/$($azSubscriptions.Id)/resourceGroups/rg-wvd-images/providers/Microsoft.Compute/galleries/sigWVDImages/images/Win10-MU-ImgDef`",`"namePrefix`":`"sh-$($postFix)`",`"osDiskType`"`:`"StandardSSD_LRS`",`"useManagedDisks`"`:true,`"vmSize`"`:{`"id`"`:`"Standard_D2s_v3`",`"cores`"`:2,`"ram`"`:8},`"galleryItemId`"`:null}";
            "tokenExpirationTime" = $(Get-Date ((Get-Date).AddDays(25)) -Format "yyyy-MM-ddTHH:mm:ss.fffZ");
            "apiVersion" = "2019-12-10-preview";
            "validationEnvironment" = $false;
            "administratorAccountUsername" = "$($domainAdminUser)";
            "domain"="$($domainName)";
            "ouPath"="$($ouPath)";
        }
        ## Show objTemplateParameter
        #$objTemplateParameter

        # ARM Template file
        $jsonARMTemplateFile = "..\ARMTemplates\ARM-T-WVDCreateHostpool.json"

        # Create WVD Hostpool, based on ARM Template
        New-AzResourceGroupDeployment -ResourceGroupName "rg-wvd-infra" -TemplateFile $jsonARMTemplateFile -TemplateParameterObject $objTemplateParameter -administratorAccountPassword $SecureAdminPassword -Verbose
    }
    else 
    {
        Write-Warning "No Azure Credentials could be retrieved from the stored credentials file for this user."
    }}
Else
{
    Write-Warning "The Az PowerShell Module, used by this Script Action, requires a minimum version of .NET Framework version 4.7.2. Please upgrade the .NET Framework version on this machine"
}

# Disconnect the Azure Session
Disconnect-AzAccount | Out-Null

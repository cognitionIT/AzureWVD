<#
.SYNOPSIS
    Add additional VM(s) to a WVD Hostpool based on an ARM template.
.DESCRIPTION
    Add additional VM(s) to a WVD Hostpool based on an ARM template, using the new Az.Desktopvirtualization PowerShell Module and WVD ARM Architecture (2020 Spring Release).
.EXAMPLE
    Invoke-WVDARMAddVMToHostpool -HostPoolName <string> -NumberOfInstances <int>
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
    [Parameter(
        Position=0, 
        Mandatory=$true, 
        HelpMessage='Enter the Hostpool Name'
    )]
    [ValidateNotNullOrEmpty()]
    [string] $HostPoolName,

    [Parameter(
        Position=1, 
        Mandatory=$true, 
        HelpMessage='Enter the number of instances to add to the Hostpool'
    )]
    [ValidateNotNullOrEmpty()]
    [int] $NumberOfInstances
) 

# dot sourcing WVD Functions
. ".\WVDFunctions.ps1"

#------------------------#
# Script Action Workflow #
#------------------------#
Write-Host ""

#region Retrieve input parameters
If ([string]::IsNullOrEmpty($HostPoolName))
{
    Write-Warning "No Host Pool name specified"
    Break
}
#endregion

## Check if the required PowerShell Modules are installed and can be imported
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Accounts" #-Verbose
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.DesktopVirtualization" #-Verbose
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Resources" #-Verbose                 # Module for ARM Deployments
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Compute" #-Verbose                   # Module for AvailabilitySets, VMs
Invoke-CheckInstallAndImportPSModulePrereq -ModuleName "Az.Network" #-Verbose                   # Module for NIC
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

        # Retrieve the Subscription information for the Service Principal (that is logged on)
        $azSubscriptions = Get-AzSubscription

        # Retrieve the given Host Pool information
        try 
        {
            $hostPool = Get-AzWvdHostPool -SubscriptionId $($azSubscriptions.Id) | Where {$_.Name -eq $HostPoolName}
        }
        catch 
        {
            Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
            Exit
        }
        If ($hostPool.Count -gt 0)
        {
            $hostpoolRG = $hostPool.Id.Split("/")[4]
            $hostpoolName = $hostPool.Id.Split("/")[-1]
            # Retrieve the current Session Host information
            try
            {
                $sessionHosts = Get-AzWvdSessionHost -HostPoolName $($hostpool.Name) -ResourceGroupName $($hostpoolRG)
            }
            catch
            {
                Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
                Exit
            }
            $sessionHost = $sessionHosts[0]
            
            # Retrieve sensitive information from KeyVault
            $secureAdminPassword = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainadminpassword).SecretValue
            $secureDomainAdminUser = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainadminuser).SecretValue
            $secureDomainName = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainname).SecretValue
            $secureOuPath = (Get-AzKeyVaultSecret -VaultName kv-infrasecrets -Name domainoupath).SecretValue
        
            # Convert SecureString to Plaintext
            $domainAdminUser = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureDomainAdminUser)))
            $domainName = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureDomainName)))
            $ouPath = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureOuPath)))

            # Retrieve the VMTemplate information
            $vmTemplate = ($hostPool.VMTemplate | ConvertFrom-Json)

            # Retrieve the vNet and subnet information of the VM
            $sessionHostName = $($sessionHost.Name.Split("/")[1].Split(".")[0])
            $sessionHostRG = (Get-AzVM -Name $sessionHostName).ResourceGroupName
            $sessionHostLocation = (Get-AzVM -Name $sessionHostName).Location
            $vnetInfo = (Get-AzNetworkInterface -ResourceGroupName $sessionHostRG | where {$_.Name -like "$($sessionHostName)*"}).IpConfigurations[0].Subnet.id.Split("/")[8]
            $subnetInfo = (Get-AzNetworkInterface -ResourceGroupName $sessionHostRG | where {$_.Name -like "$($sessionHostName)*"}).IpConfigurations[0].Subnet.id.Split("/")[10]
            $vnetrgInfo = (Get-AzNetworkInterface -ResourceGroupName $sessionHostRG | where {$_.Name -like "$($sessionHostName)*"}).IpConfigurations[0].Subnet.id.Split("/")[4]

            # Retrieve Hostpool token
            $registrationInfo = Get-AzWvdRegistrationInfo -SubscriptionId $($azSubscriptions.Id) -ResourceGroupName $($hostpoolRG) -HostPoolName $($hostpoolName)
            if ($($registrationInfo.ExpirationTime) -le $((Get-Date).ToUniversalTime().ToString('MM/dd/yyyy HH:mm:ss')) -and $(!([string]::IsNullOrEmpty($registrationInfo.ExpirationTime))))
            {
                $hostpoolToken = $registrationInfo.Token
            }
            else
            {
                $hostpoolToken = $((New-AzWvdRegistrationInfo -ResourceGroupName $hostpoolRG -HostPoolName $HostPoolName -ExpirationTime $((Get-Date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))).Token)
            }

            ## Create a Template Parameter Object (hashtable)
            $objTemplateParameter = @{
                "hostpoolName" = $HostPoolName;
                "hostpoolToken" = $($hostpoolToken);
                "hostpoolResourceGroup" = $($hostPool.Id.Split("/")[4]);
                "hostpoolProperties" = @{};
                "hostpoolLocation" = $($hostPool.Location);
                "createAvailabilitySet" = $false;
                "vmInitialNumber" = $($sessionHosts.Count);
                "vmResourceGroup" = $($sessionHostRG);
                "vmLocation" = $($sessionHostLocation);
                "vmSize" = $($vmTemplate.vmSize.id);
                "vmNumberOfInstances" = $NumberOfInstances;
                "vmNamePrefix" = $($vmTemplate.namePrefix);
                "vmImageType" = $($vmTemplate.imageType);
                "vmImageVhdUri" = [string]$($vmTemplate.imageUri);
                "vmDiskType" = $($vmTemplate.osDiskType);
                "vmUseManagedDisks" = $($vmTemplate.useManagedDisks);
                "existingVnetName" = $($vnetInfo);
                "existingSubnetName" = $($subnetInfo);
                "virtualNetworkResourceGroupName" = $($vnetrgInfo);
                "usePublicIP" = $false;
                "createNetworkSecurityGroup" = $false;
                "apiVersion" = "2019-12-10-preview";
                "vmGalleryImageOffer" = $($vmTemplate.galleryImageOffer);
                "vmGalleryImagePublisher" = $($vmTemplate.galleryImagePublisher);
                "vmGalleryImageSKU" = $($vmTemplate.galleryImageSKU);
                "administratorAccountUsername" = "$($domainAdminUser)";
                "domain"="$($domainName)";
                "ouPath"="$($ouPath)";
            }
            ## Show objTemplateParameter
            #$objTemplateParameter

            # ARM Template file
            $jsonARMTemplateFile = "..\ARMTemplates\ARM-T-WVDAddSessionHostToHostpool.json"

            ## Add SessionHosts to existing WVD Hostpool, based on ARM Template
            New-AzResourceGroupDeployment -ResourceGroupName $hostpoolRG -TemplateFile $jsonARMTemplateFile -TemplateParameterObject $objTemplateParameter -administratorAccountPassword $secureAdminPassword -Verbose
        }
    }
    else 
    {
        Write-Warning "No Azure Credentials could be retrieved from the stored credentials file for this user."
    }}
Else
{
    Write-Warning "The Az PowerShell Module, requires a minimum version of .NET Framework version 4.7.2. Please upgrade the .NET Framework version on this machine"
}

# Disconnect the Azure Session
Disconnect-AzAccount | Out-Null

<#
.SYNOPSIS
    Repository for all WVD Functions to support the WVD PowerShell scripts.
.DESCRIPTION
    Repository for all WVD Functions to support the WVD PowerShell scripts, based on REST API calls.
.NOTES
    Version:        1.0
    Author:         Esther Barthel, MSc
    Creation Date:  2020-08-03
    Updated:        2020-08-15
    Purpose:        WVD Administration centralized functions, using REST API calls
        
    Copyright (c) cognition IT. All rights reserved.
#>

#region Global Variables
$wvdApiVersion = "2019-12-10-preview"
#endregion Global Variables

#region Windows Presentation Foundation (WPF) form to store WVD Service Principal information
[string]$mainformXAML = @'
<Window x:Class="wvdSP_Input_Form.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Esther_s_Input_Form"
        mc:Ignorable="d"
        Title="Enter the WVD Service Principal (SP) details" Height="389.336" Width="617.103">
    <Grid>
        <TextBox x:Name="textboxTenantId" HorizontalAlignment="Left" Height="31" Margin="176,50,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="398"/>
        <Label Content="SP Tenant ID" HorizontalAlignment="Left" Height="30" Margin="29,51,0,0" VerticalAlignment="Top" Width="117"/>
        <TextBox x:Name="textboxAppId" HorizontalAlignment="Left" Height="30" Margin="176,118,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="398"/>
        <Label Content="SP App ID" HorizontalAlignment="Left" Height="30" Margin="29,118,0,0" VerticalAlignment="Top" Width="117"/>
        <PasswordBox x:Name="textboxAppSecret" HorizontalAlignment="Left" Height="31" Margin="176,192,0,0" VerticalAlignment="Top" Width="398"/>
        <Label Content="SP App Secret" HorizontalAlignment="Left" Height="30" Margin="29,193,0,0" VerticalAlignment="Top" Width="117"/>
        <Button x:Name="buttonOK" Content="OK" HorizontalAlignment="Left" Height="46" Margin="29,274,0,0" VerticalAlignment="Top" Width="175" IsDefault="True"/>
        <Button x:Name="buttonCancel" Content="Cancel" HorizontalAlignment="Left" Height="46" Margin="244,274,0,0" VerticalAlignment="Top" Width="175" IsDefault="True"/>

    </Grid>
</Window>
'@

function Invoke-WVDSPCredentialsForm {
# Created by Guy Leech - @guyrleech 17/05/2020
    Param
    (
        [Parameter(Mandatory=$true)]
        $inputXaml
    )

    $form = $null
    $inputXML = $inputXaml -replace 'mc:Ignorable="d"' , '' -replace 'x:N' ,'N'  -replace '^<Win.*' , '<Window'
    [xml]$xaml = $inputXML

    if( $xaml )
    {
        $reader = New-Object -TypeName Xml.XmlNodeReader -ArgumentList $xaml

        try
        {
            $form = [Windows.Markup.XamlReader]::Load( $reader )
        }
        catch
        {
            Throw "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .NET is installed.`n$_"
        }

        $xaml.SelectNodes( '//*[@Name]' ) | ForEach-Object `
        {
            Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -Scope Global
        }
    }
    else
    {
        Throw "Failed to convert input XAML to WPF XML"
    }

    $form
}
#endregion WPF form

#region Azure Service Principal Stored Credentials (encrypted and linked to machine and user)
function Get-AzSPStoredCredentials {
    <#
    .SYNOPSIS
        Retrieve the Azure Service Principal Stored Credentials.
    .DESCRIPTION
        Retrieve the Azure Service Principal Stored Credentials from a stored credentials file.
    .EXAMPLE
        Get-AzSPStoredCredentials
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-08-03
        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param()

    #region function settings
        # Stored Credentials XML file
        $System = "AZ"
        $strAzSPCredFolder = "$($env:APPDATA)"
        $AzSPCredentials = $null
    #endregion

    Write-Verbose ""
    Write-Verbose "----------------------------- "
    Write-Verbose "| Get Azure SP Credentials: | "
    Write-Verbose "----------------------------- "
    Write-Verbose ""

    If (Test-Path -Path "$($strAzSPCredFolder)\$($env:USERNAME)_$($System)_Cred.xml")
    {
        try 
        {
            $AzSPCredentials = Import-Clixml -Path "$strAzSPCredFolder\$($env:USERNAME)_$($System)_Cred.xml"
        }
        catch 
        {
            Write-Error ("The required PSCredential object could not be loaded. " + $_)
        }
    }
    Else
    {
        Write-Error "The Azure Service Principal Credentials file stored for this user ($($env:USERNAME)) cannot be found. `nCreate the file with the Set-AzSPCredentials script action (prerequisite)."
        Exit
    }
    return $AzSPCredentials
}

function Set-AzSPStoredCredentials {
    <#
    .SYNOPSIS
        Store the Azure Service Principal Credentials.
    .DESCRIPTION
        Store the Azure Service Principal Credentials to an encrypted stored credentials file.
    .EXAMPLE
        Set-AzSPStoredCredentials
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-08-03
        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
    )

    #region function settings
        # Stored Credentials XML file
        $System = "AZ"
        $strAzSPCredFolder = "$($env:APPDATA)"
        $AzSPCredentials = $null
    #endregion

    Write-Verbose ""
    Write-Verbose "------------------------------- "
    Write-Verbose "| Store Azure SP Credentials: | "
    Write-Verbose "------------------------------- "
    Write-Verbose ""

    If (!(Test-Path -Path "$($strAzSPCredFolder)"))
    {
        New-Item -ItemType Directory -Path "$($strAzSPCredFolder)"
        Write-Verbose "* AzSPCredentials: Path $($strAzSPCredFolder) created"
    }
    try 
    {
        Add-Type -AssemblyName PresentationFramework
        # Show the Form that will ask for the WVD Service Principal information (tenant ID, App ID, & App Secret)
        if( $mainForm = Invoke-WVDSPCredentialsForm -inputXaml $mainformXAML )
        {
            $WPFbuttonOK.Add_Click( {
                $_.Handled = $true
                $mainForm.DialogResult = $true
                $mainForm.Close()
            })
        
            $WPFbuttonCancel.Add_Click( {
                $_.Handled = $true
                $mainForm.DialogResult = $false
                $mainForm.Close()
            })
        
            $null = $WPFtextboxTenantId.Focus()
        
            if( $mainForm.ShowDialog() )
            {
                # Retrieve the form input (and check for errors)
                # tenant ID
                If ([string]::IsNullOrEmpty($($WPFtextboxTenantId.Text)))
                {
                    Write-Error "The provided tenant ID is empty!"
                    Exit
                }
                else 
                {
                    $tenantID = $($WPFtextboxTenantId.Text)
                }
                # app ID
                If ([string]::IsNullOrEmpty($($WPFtextboxAppId.Text)))
                {
                    Write-Error "The provided app ID is empty!"
                    Exit
                }
                else 
                {
                    $appID = $($WPFtextboxAppId.Text)
                }
                # app Secret
                If ([string]::IsNullOrEmpty($($WPFtextboxAppSecret.Password)))
                {
                    Write-Error "The provided app Secret is empty!"
                    Exit
                }
                else 
                {
                    $appSecret = $($WPFtextboxAppSecret.Password)
                }

                
                $appSecret = $($WPFtextboxAppSecret.Password)
            }
            else 
            {
                Write-Error "The required tenant ID, app ID and app Secret could not be retrieved from the form."
                Break
            }
        }
    }
    catch
    {
        Write-Error ("The required information could not be retrieved from the input form. " + $_)
        Exit        
    }
        # Create the SP Credentials, so they are encrypted before being stored in the XML file
        $secureAppSecret = ConvertTo-SecureString -String $appSecret -AsPlainText -Force
        $spCreds = New-Object System.Management.Automation.PSCredential($appID, $secureAppSecret)

    try
    {
        $hashAzSPCredentials = @{
            'tenantID' = $tenantID
            'spCreds' = $spCreds
        }
        $AzSPCredentials = Export-Clixml -Path "$strAzSPCredFolder\$($env:USERNAME)_$($System)_Cred.xml" -InputObject $hashAzSPCredentials -Force
    }
    catch 
    {
        Write-Error ("The required PSCredential object could not be exported. " + $_)
        Exit
    }
    Write-Verbose "* AzSPCredentials: Exported succesfully."
    return $hashAzSPCredentials
}
#endregion Azure Service Principal Stored Credentials (encrypted and linked to machine and user)

#region Azure Authentication Functions
function Get-AzBearerToken {
    <#
    .SYNOPSIS
        Retrieve the Azure Bearer Token for an authentication session.
    .DESCRIPTION
        Retrieve the Azure Bearer Token for an authentication session, using a REST API call.
    .EXAMPLE
        Get-AzBearerToken -SPCredentials <PSCredentialObject> -TenantID <string>
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-03-22
        Updated:        2020-05-08
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions
        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the Service Principal credentials'
        )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential] $SPCredentials,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Tenant ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $TenantID
    )

    #region Prep variables
        # URL for REST API call to authenticate with Azure (using the TenantID parameter)
        $uri = "https://login.microsoftonline.com/$TenantID/oauth2/token"
        
        # Create the Invoke-RestMethod Body (using the SPCredentials parameter)
        $body = @{
            grant_type="client_credentials";
            client_Id=$($SPCredentials.UserName);
            client_Secret=$($SPCredentials.GetNetworkCredential().Password);
            resource="https://management.azure.com"
        }
        #debug: $body

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Body            = $body
            Method          = "POST"
            ContentType     = "application/x-www-form-urlencoded"
        }
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    # return the JSON response
    return $response
}

function Get-AzGraphBearerToken {
    <#
    .SYNOPSIS
        Retrieve the Azure Bearer Token for an Graph authentication session.
    .DESCRIPTION
        Retrieve the Azure Bearer Token for an Graph authentication session, using a REST API call.
    .EXAMPLE
        Get-AzGraphBearerToken -SPCredentials <PSCredentialObject> -TenantID <string>
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-08-24
        Updated:        2020-08-24

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter the Service Principal credentials'
        )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential] $SPCredentials,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Tenant ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $TenantID
    )

    #region Prep variables
        # URL for REST API call to authenticate with Azure Graph (using the TenantID parameter)
        $uri = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        
        # Create the Invoke-RestMethod Body (using the SPCredentials parameter)
        $body = @{
            grant_type="client_credentials";
            client_id=$($SPCredentials.UserName);
            client_secret=$($SPCredentials.GetNetworkCredential().Password);
            scope="https://graph.microsoft.com/.default"
        }
        #debug: $body

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Body            = $body
            Method          = "POST"
            ContentType     = "application/x-www-form-urlencoded"
        }
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    # return the JSON response
    return $response
}
#endregion Azure Authentication Functions

#region Azure Authorization Functions
function Get-AzRoleDefinition {
    <#
    .SYNOPSIS
        Retrieve the Azure Role Definition.
    .DESCRIPTION
        Retrieve the Azure Role Definition, using a REST API call.
    .EXAMPLE
        Get-AzRoleDefinition -BearerToken <string> -SubscriptionID <string> -RoleDefinitionID <string>
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter a Subscription ID'
        )]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter a Role Definition ID'
        )]
        [string] $RoleDefinitionID
    )

    #region Prep variables
        # URL for REST API call to retrieve Role Definition (using the RoleDefinitionID parameter)
        $uri = "https://management.azure.com//subscriptions/$SubscriptionID/providers/Microsoft.Authorization/roleDefinitions/$RoleDefinitionID`?api-version=2015-07-01"
        #debug: $uri

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
        #debug: $response
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    $results = $response.properties
    return $results
}
#endregion Azure Authorization Functions

#region Azure Resources Functions
function Get-AzSubscription {
    <#
    .SYNOPSIS
        Retrieve the Azure Subscription information.
    .DESCRIPTION
        Retrieve the Azure Subscription information, using a REST API call.
    .EXAMPLE
        Get-AzSubscription -BearerToken <string> -SubscriptionID <string>
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$false, 
            HelpMessage='Enter a subscriptionID'
        )]
        [string] $SubscriptionID
    )

    #region Prep variables
        # URL for REST API call to authenticate with Azure (using the TenantID parameter)
        $uri = "https://management.azure.com/subscriptions?api-version=2020-01-01"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    # filter the response if a SubscriptionID was provided
    If (!([string]::IsNullOrEmpty($subScriptionID)))
    {
        $results = ($response.value).Where({$_.subscriptionId -like "$subScriptionID"})
    }
    else 
    {
        $results = $response.value
    }
    return $results
}
#endregion Azure Resources Functions

#region Microsoft Graph Functions
function Get-AADObjectByPrincipalId () {
    <#
    .SYNOPSIS
        Retrieve Azure AD Objects by Principal ID.
    .DESCRIPTION
        Retrieve Azure AD Objects by Principal ID, using a REST API call.
    .EXAMPLE
        Get-AADObjectByPrincipalId -BearerToken <string> -PrincipalID <string>
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Principal ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $PrincipalID
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://graph.microsoft.com//v1.0/directoryObjects/getByIds"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the JSON formatted body
        $body = @{
            "ids" = @($PrincipalID);
            "types" = @("user", "group") 
        }
        $bodyJSON = ConvertTo-Json -InputObject $body -Depth 10

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "POST"
            Headers         = $header
            Body            = $bodyJSON
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    $results = $response.value
    return $results
}
#endregion Microsoft Graph Functions

#region WVD Host Pool Functions
function Get-WVDHostPool () {
    <#
    .SYNOPSIS
        Retrieve WVD Host Pool information.
    .DESCRIPTION
        Retrieve WVD Host Pool information, using a REST API call.
    .EXAMPLE
        Get-WVDHostPool -BearerToken <string> -SubscriptionID <string> -[-HostPoolName <string>]
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$false, 
            HelpMessage='Enter the Hostpool Name'
        )]
        [string] $HostPoolName
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://management.azure.com/subscriptions/$SubscriptionID/providers/Microsoft.DesktopVirtualization/hostPools`?api-version=$wvdApiVersion"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    # filter the response if a HostPoolName was provided
    If (!([string]::IsNullOrEmpty($HostPoolName)))
    {
        $results = ($response.value).Where({$_.name -like "$HostPoolName"})
    }
    else 
    {
        $results = $response.value
    }
    return $results
}

function Set-WVDHostPool () {
    <#
    .SYNOPSIS
        Update the WVD Host Pool information.
    .DESCRIPTION
        Update the WVD Host Pool information, using a REST API call.
    .EXAMPLE
        Set-WVDHostPool -BearerToken <string> -SubscriptionID <string> -ResourceGroupName <string> -HostPoolName <string> [-FriendlyName <string> -Description <string> -CustomRdpProperty <string> -MaxSessionLimit <string> -LoadBalancerType <string> -PersonalDesktopAssignmentType <string> -RegistrationTokenDays <string> -SSOContext <string>]
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter the Resource Group Name'
        )]
        [string] $ResourceGroupName,

        [Parameter(
            Position=3, 
            Mandatory=$true, 
            HelpMessage='Enter the HostPool Name'
        )]
        [string] $HostPoolName,

        [Parameter(
            Position=4, 
            Mandatory=$false, 
            HelpMessage='Enter the friendlyName Property'
        )]
        [string] $FriendlyName,

        [Parameter(
            Position=5, 
            Mandatory=$false, 
            HelpMessage='Enter the description Property'
        )]
        [string] $Description,

        [Parameter(
            Position=6, 
            Mandatory=$false, 
            HelpMessage='Enter the customRdpProperty Property'
        )]
        [string] $CustomRdpProperty,

        [Parameter(
            Position=7, 
            Mandatory=$false, 
            HelpMessage='Enter the maxSessionLimit Property'
        )]
        [string] $MaxSessionLimit,

        [Parameter(
            Position=8, 
            Mandatory=$false, 
            HelpMessage='Enter the loadBalancerType Property'
        )]
        [string] $LoadBalancerType,

        [Parameter(
            Position=9, 
            Mandatory=$false, 
            HelpMessage='Enter the personalDesktopAssignmentType Property'
        )]
        [string] $PersonalDesktopAssignmentType,

        [Parameter(
            Position=10, 
            Mandatory=$false, 
            HelpMessage='Enter the number of days for the registration token'
        )]
        [string] $RegistrationTokenDays,

        [Parameter(
            Position=11, 
            Mandatory=$false, 
            HelpMessage='Enter the ssoContext Property'
        )]
        [string] $SSOContext
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName`?api-version=$wvdApiVersion"
        #debug: $uri

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }

        # Create the Invoke-RestMethod Body (using the property parameters)
        $body = @{}
        $properties = @{}
        # Add the properties to update
        If (!([string]::IsNullOrEmpty($FriendlyName)))
        {
            $properties.Add("friendlyName",$FriendlyName)
        }
        If (!([string]::IsNullOrEmpty($Description)))
        {
            $properties.Add("description",$Description)
        }
        If (!([string]::IsNullOrEmpty($CustomRdpProperty)))
        {
            $properties.Add("customRdpProperty",$CustomRdpProperty)
        }
        If (!([string]::IsNullOrEmpty($MaxSessionLimit)))
        {
            $properties.Add("maxSessionLimit",$MaxSessionLimit)
        }
        If (!([string]::IsNullOrEmpty($LoadBalancerType)))
        {
            $properties.Add("loadBalancerType",$LoadBalancerType)
        }
        If (!([string]::IsNullOrEmpty($PersonalDesktopAssignmentType)))
        {
            $properties.Add("personalDesktopAssignmentType",$PersonalDesktopAssignmentType)
        }
        If (!([string]::IsNullOrEmpty($SSOContext)))
        {
            $properties.Add("ssoContext",$SSOContext)
        }
        If (!([string]::IsNullOrEmpty($RegistrationTokenDays)))
        {
            [string]$expirationTime = (Get-Date -Date (Get-Date).AddDays([int]$RegistrationTokenDays)).ToString("yyyy-MM-ddTHH:mm:ssZ")
            #debug: Write-Output "expirationTime= $expirationTime"
            $registrationInfo = @{
                "expirationTime"=$expirationTime;
                # registrationTokenOperation = Delete | None | Update
                "registrationTokenOperation"="Update"
            }
            $properties.Add("registrationInfo",$RegistrationInfo)
        }

        If ($properties.Count -gt 0)
        {
            $body.properties = $properties
        }
        $bodyJSON = ConvertTo-Json -InputObject $body -Depth 10
        #debug $bodyJSON

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "Patch"
            Headers         = $header
            Body            = $bodyJSON
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    return $response
}
#endregion WVD Host Pool Functions

#region WVD Workspace Functions
function Get-WVDWorkspace () {
    <#
    .SYNOPSIS
        Retrieve the WVD Workspace information.
    .DESCRIPTION
        Retrieve the WVD Workspace information, using a REST API call.
    .EXAMPLE
        Get-WVDWorkspace -BearerToken <string> -SubscriptionID <string> [-WorkspaceName <string>]
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$false, 
            HelpMessage='Enter the Workspace Name'
        )]
        [string] $WorkspaceName
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://management.azure.com/subscriptions/$SubscriptionID/providers/Microsoft.DesktopVirtualization/workspaces`?api-version=$wvdApiVersion"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    #debug: $response.value

    # filter the response if a WorkspaceName was provided
    If (!([string]::IsNullOrEmpty($WorkspaceName)))
    {
        $results = ($response.value).Where({$_.name -like "$WorkspaceName"})
    }
    else 
    {
        $results = $response.value
    }
    return $results
}
#endregion WVD Workspace Functions

#region WVD Application Group Functions
function Get-WVDApplicationGroup () {
    <#
    .SYNOPSIS
        Retrieve the WVD Application Group information.
    .DESCRIPTION
        Retrieve the WVD Application Group information, using a REST API call.
    .EXAMPLE
        Get-WVDApplicationGroup -BearerToken <string> -SubscriptionID <string> [-ApplicationGroupName <string>]
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$false, 
            HelpMessage='Enter the Application Group Name'
        )]
        [string] $ApplicationGroupName
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://management.azure.com/subscriptions/$SubscriptionID/providers/Microsoft.DesktopVirtualization/applicationGroups`?api-version=$wvdApiVersion"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    #debug: $response.value

    # filter the response if a ApplicationGroupName was provided
    If (!([string]::IsNullOrEmpty($ApplicationGroupName)))
    {
        $results = ($response.value).Where({$_.name -like "$ApplicationGroupName"})
    }
    else 
    {
        $results = $response.value
    }
    return $results
}

function Get-WVDApplicationGroupApplication () {
    <#
    .SYNOPSIS
        Retrieve the WVD Application Group Application information.
    .DESCRIPTION
        Retrieve the WVD Application Group Application information, using a REST API call.
    .EXAMPLE
        Get-WVDApplicationGroupApplication -BearerToken <string> -SubscriptionID <string> -ResourceGroupName <string> -ApplicationGroupName <string> [-ApplicationName <string]
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter the Resource Group Name'
        )]
        [string] $ResourceGroupName,

        [Parameter(
            Position=3, 
            Mandatory=$true, 
            HelpMessage='Enter the Application Group Name'
        )]
        [string] $ApplicationGroupName,

        [Parameter(
            Position=4, 
            Mandatory=$false, 
            HelpMessage='Enter the Application Name'
        )]
        [string] $ApplicationName
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.DesktopVirtualization/applicationGroups/$ApplicationGroupName/applications`?api-version=$wvdApiVersion"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    #debug: $response.value

    # filter the response if a ApplicationName was provided
    If (!([string]::IsNullOrEmpty($ApplicationName)))
    {
        $results = ($response.value).Where({($_.name.Split("/")[1]) -like "$ApplicationName"})
    }
    else 
    {
        $results = $response.value
    }
    return $results
}

function Get-WVDApplicationGroupAssignment () {
    <#
    .SYNOPSIS
        Retrieve the WVD Application Group Assignment information.
    .DESCRIPTION
        Retrieve the WVD Application Group Assignment information, using a REST API call.
    .EXAMPLE
        Get-WVDApplicationGroupAssignment -BearerToken <string> -SubscriptionID <string> -ResourceGroupName <string> -ApplicationGroupName <string>
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$true, 
            HelpMessage='Enter the Resource Group Name'
        )]
        [string] $ResourceGroupName,

        [Parameter(
            Position=3, 
            Mandatory=$true, 
            HelpMessage='Enter the Application Group Name'
        )]
        [string] $ApplicationGroupName
    )
    #region Prep variables
        # URL for REST API call to list hostpools, based on given subscription ID
        $uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups/$ResourceGroupName/providers/Microsoft.DesktopVirtualization/applicationGroups/$ApplicationGroupName/providers/Microsoft.Authorization/roleAssignments`?api-version=2015-07-01"

        # Create the Invoke-RestMethod Header (using the bearertoken parameter)
        $header = @{
            "Authorization"="Bearer $BearerToken"; 
            "Content-Type" = "application/json"
        }
        #debug: $header

        # Create the Invoke-RestMethod parameters
        $invokeRestMethodParams = @{
            Uri             = $uri
            Method          = "GET"
            Headers          = $header
        }
        #debug: $invokeRestMethodParams
    #endregion

    try 
    {
        $response = $null
        # Make the REST API call with the created parameters
        $response = Invoke-RestMethod @invokeRestMethodParams
    }
    catch 
    {
        Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
    }
    #debug: $response.value

    $results = $response.value
    return $results
}
#endregion WVD Application Group Functions

#region WVD User Session Functions
function Get-WVDUserSession () {
    <#
    .SYNOPSIS
        Retrieve the WVD User Session information.
    .DESCRIPTION
        Retrieve the WVD User Session information, using a REST API call.
    .EXAMPLE
        Get-WVDUserSession -BearerToken <string> -SubscriptionID <string> -ResourceGroupName <string> [-UserPrincipalName <string>]
    .CONTEXT
        Azure
    .NOTES
        Version:        0.1
        Author:         Esther Barthel, MSc
        Creation Date:  2020-09-20
        Updated:        2020-09-20
                        Created a separate Azure Credentials function to support ARM architecture and REST API scripted actions

        Purpose:        WVD Administration, through REST API calls
        
        Copyright (c) cognition IT. All rights reserved.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            HelpMessage='Enter a valid bearer token'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $BearerToken,

        [Parameter(
            Position=1, 
            Mandatory=$true, 
            HelpMessage='Enter the Subscription ID'
        )]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionID,

        [Parameter(
            Position=2, 
            Mandatory=$false, 
            HelpMessage='Enter the User Principal Name'
        )]
        [string] $UserPrincipalName
    )

    # Check if the HostPoolName parameter is empty or not
    If ([string]::IsNullOrEmpty($UserPrincipalName))
    {
        $UserPrincipalName = "*"
    }
    # Retrieve the HostPool Names first
    [array]$wvdUserSessionCollection = Get-WVDHostPool -BearerToken $BearerToken -SubscriptionID $SubscriptionID | 
    foreach {
        $hostpool = $_
        #region Prep variables
            # URL for REST API call to list hostpools, based on given subscription ID
            $resourceGroupName = $hostpool.id.Split("/")[4]
            $name=$hostpool.name
            $uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$resourceGroupName/providers/Microsoft.DesktopVirtualization/hostPools/$name/userSessions?api-version=$wvdApiVersion"

            # Create the Invoke-RestMethod Header (using the bearertoken parameter)
            $header = @{
                "Authorization"="Bearer $BearerToken"; 
                "Content-Type" = "application/json"
            }
            #debug: $header

            # Create the Invoke-RestMethod parameters
            $invokeRestMethodParams = @{
                Uri             = $uri
                Method          = "GET"
                Headers          = $header
            }
            #debug: $invokeRestMethodParams
        #endregion

        try 
        {
            $response = $null
            # Make the REST API call with the created parameters
            $response = Invoke-RestMethod @invokeRestMethodParams
        }
        catch 
        {
            Write-Error ("A [" + $_.Exception.GetType().FullName + "] ERROR occurred. " + $_.Exception.Message)
        }
        If ($response.value.properties.userPrincipalName -like "$UserPrincipalName")
        {
            $response.value | Select *
        }
    }
    return $wvdUserSessionCollection
}
#endregion WVD User Session Functions




# SIG # Begin signature block
# MIINHAYJKoZIhvcNAQcCoIINDTCCDQkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU46EtJ9eYow34DlqRI+9xNZi7
# 0SKgggpeMIIFJjCCBA6gAwIBAgIQCyXBE0rAWScxh3bGfykLTjANBgkqhkiG9w0B
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
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQ30S1LBN/W
# /j2MjceZlruhG/iYojANBgkqhkiG9w0BAQEFAASCAQABQe++FZXh1TLvJCBnuB6t
# QsHYBO29TM8sEteqpxbm49w+bRXb9beBy4B1gupwpkU/mLWzoL1R81yfGE0mCjqI
# RiIZlfO9769HIUQZJXwVRkULtCMRdcW554DaqfV9rLS87FZy7M9rKRuF6hKr6sSN
# m0IIAQ2OYk3yWreDEY0F5lxEwVNCf9/q6BIasn/L16xT6bUocw9ZZHrfN/SazGPD
# ubZoqNzP3eZLY/ZNsIXepnlG+jhsBgX0zBqoBW9qkd/wZ+WfDyUAJfQnW7QIMLFl
# +TnE2clt1YhH3yWfKgcdVcsukpO06H0x2CknrKybXK1mHOmXNN6zQa4NCUHeH87X
# SIG # End signature block

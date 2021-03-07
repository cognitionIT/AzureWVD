﻿          ## Update the Az Module to 5.6.0+ (does not work with GitHub Actions as it is not installed using Install-Module)
          #Update-Module -Name Az -RequiredVersion 5.6.0 -Force #-ErrorAction SilentlyContinue

          # Read the GitHub Actions variables
          [string]$githubWorkspace = "${{GITHUB.WORKSPACE}}"

          # Read the environment variables in PowerShell
          [string]$location = [System.Environment]::GetEnvironmentVariable('LOCATION')
          [string]$bicepFilePath = [System.Environment]::GetEnvironmentVariable('BICEP_FILE_PATH')
          [string]$resourcegroupName = [System.Environment]::GetEnvironmentVariable('RESOURCE_GROUP_NAME')
          
          Write-Output ("* BICEP FILE PATH: " + $($bicepFilePath))
          Write-Output ("* RESOURCE GROUP NAME: " + $($resourcegroupName))
          Write-Output ("* GITHUB_WORKSPACE: " + $($githubWorkspace))

          $namePostFix = $resourcegroupName.Replace("rg-","")

          ## Create a Template Parameter Object (hashtable)
          $objTemplateParameter = @{
            "location" = "$($location)";
            "workSpaceName" = "ws-wvd-$($namePostFix)";
            "hostpoolName" = "hp-wvd-$($namePostFix)";
            "appgroupName" = "ag-wvd-$($namePostFix)";
            "preferredAppGroupType" = "Desktop";
            "hostPoolType" = "pooled";
            "loadbalancertype" = "DepthFirst";
            "appgroupType" = "Desktop";
          }
            
          # Show objTemplateParameter
          $objTemplateParameter
          
          # Location of the bicep file in the local checked-out repo
          $biceptemplateFile = [string]("$($githubWorkspace)" + "\" + "$($bicepFilePath)")
          Write-Output ("* BICEP TEMPLATE FILE: " + $($biceptemplateFile))

          # Create the resourceGroup
          New-AzResourceGroup -Name $resourcegroupName -Location $location

          # ARM Template file
          ## Deploy resources based on bicep file for ARM Template
          New-AzResourceGroupDeployment -ResourceGroupName $resourcegroupName -TemplateFile $($biceptemplateFile) -TemplateParameterObject $objTemplateParameter -Verbose

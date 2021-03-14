          ## Update the Az Module to 5.6.0+ (does not work with GitHub Actions runner as it is not installed using Install-Module)
          #Update-Module -Name Az -RequiredVersion 5.6.0 -Force #-ErrorAction SilentlyContinue

          # Read the GitHub Actions variables
          [string]$githubWorkspace = "${{GITHUB.WORKSPACE}}"

          # Read the environment variables
          [string]$location = [System.Environment]::GetEnvironmentVariable('LOCATION')
          [string]$bicepFile = [System.Environment]::GetEnvironmentVariable('BICEP_FILE')
          [string]$resourcegroupName = [System.Environment]::GetEnvironmentVariable('RESOURCE_GROUP_NAME')
          
          # Debug info:
          Write-Output ("* BICEP FILE: " + $($bicepFile))
          Write-Output ("* RESOURCE GROUP NAME: " + $($resourcegroupName))
          Write-Output ("* GITHUB_WORKSPACE: " + $($githubWorkspace))

          # Use the resource group name as a postfix for the wvd components
          $namePostFix = $resourcegroupName.Replace("rg-","")

          # Create a Template Parameter Object (hashtable)
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
          ## Show objTemplateParameter (debug info)
          #$objTemplateParameter
          
          # Location of the bicep file in the local checked-out repo
          $biceptemplateFile = [string]("$($githubWorkspace)" + "\bicep\" + "$($bicepFile)")
          # Debug info: 
          Write-Output ("* BICEP TEMPLATE FILE: " + $($biceptemplateFile))

          # Create the resourcegroup
          $newResourceGroupParams = @{
            Name     = $resourcegroupName
            Location = $location
          }
          New-AzResourceGroup @newResourceGroupParams

          # Deploy Azure resources based on bicep file as ARM Template file
          $newResourceGroupDeploymentParams = @{
            ResourceGroupName = $resourcegroupName
            TemplateFile      = $($biceptemplateFile)
            TemplateParameterObject = $objTemplateParameter
          }
          New-AzResourceGroupDeployment @newResourceGroupDeploymentParams -Verbose

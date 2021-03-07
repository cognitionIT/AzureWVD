          # Read the GitHub Actions variables
          [string]$githubWorkspace = "${{GITHUB.WORKSPACE}}"

          # Read the environment variables in PowerShell
          [string]$location = [System.Environment]::GetEnvironmentVariable('LOCATION')
          [string]$bicepFile = [System.Environment]::GetEnvironmentVariable('BICEP_FILE')
          [string]$resourcegroupName = [System.Environment]::GetEnvironmentVariable('RESOURCE_GROUP_NAME')
          
          Write-Output ("* BICEP FILE: " + $($bicepFile))
          Write-Output ("* RESOURCE GROUP NAME: " + $($resourcegroupName))
          Write-Output ("* GITHUB_WORKSPACE: " + $($githubWorkspace))

          ## Create a Template Parameter Object (hashtable)
          $objTemplateParameter = @{
            "location" = "$($location)";
            "workSpaceName" = "ws-wvd-bicepdemo";
            "hostpoolName" = "hp-wvd-bicepdemo";
            "appgroupName" = "ag-wvd-bicepdemo";
            "preferredAppGroupType" = "Desktop";
            "hostPoolType" = "pooled";
            "loadbalancertype" = "DepthFirst";
            "appgroupType" = "Desktop";
          }
            
          # Show objTemplateParameter
          $objTemplateParameter
          
          # Temp location for the bicep file that will be used by this script (discarded when runbook is finished)
          $biceptemplateFile = [string]($env:TEMP + "\demo.bicep")
          
          # Storage location for bicep file template
          $templateUrl="https://raw.githubusercontent.com/cognitionIT/AzureWVD/master/Bicep/demo.bicep"
          
          # Retrieve the template file and save it in a temp file location
          Invoke-WebRequest -Uri $templateUrl -OutFile $biceptemplateFile -UseBasicParsing
          
          # Create the resourceGroup
          New-AzResourceGroup -Name $($resourcegroupName) -Location $($location)

          # ARM Template file
          ## Add SessionHosts to existing WVD Hostpool, based on ARM Template
          New-AzResourceGroupDeployment -ResourceGroupName "$($resourcegroupName)" -TemplateFile "$($biceptemplateFile)" -TemplateParameterObject $objTemplateParameter -Verbose

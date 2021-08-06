# Read the GitHub Actions built-in ariables
[string]$githubWorkspace = "${{GITHUB.WORKSPACE}}"

# Read the environment variables in PowerShell (GitHub Action inputs)
[string]$location = [System.Environment]::GetEnvironmentVariable('LOCATION')
[string]$bicepFile = [System.Environment]::GetEnvironmentVariable('BICEP_FILE')
[string]$resourcegroupName = [System.Environment]::GetEnvironmentVariable('RESOURCE_GROUP_NAME')

Write-Output ("* BICEP FILE: " + $($bicepFile))
Write-Output ("* RESOURCE GROUP NAME: " + $($resourcegroupName))
Write-Output ("* GITHUB_WORKSPACE: " + $($githubWorkspace))

## Create a Template Parameter Object (hashtable)
$objTemplateParameter = @{
  "prefix"           = "bicepdemo";
  "hostPoolType"     = "Pooled";
  "loadbalancerType" = "DepthFirst";
}

# Location of the bicep file in the local copy of the repo
$biceptemplateFile = [string]("$($githubWorkspace)" + "\bicep\" + "$($bicepFile)")
Write-Output ("* BICEP TEMPLATE FILE: " + $($biceptemplateFile))

# Create the resourceGroup (if it does not yet exist)
if (!(Get-AzResourceGroup -Name $resourcegroupName -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $resourcegroupName -Location $location
}

## Deploy resources based on bicep file for ARM Template
New-AzResourceGroupDeployment -ResourceGroupName $resourcegroupName `
  -TemplateFile $($biceptemplateFile) `
  -TemplateParameterObject $objTemplateParameter `
  -Verbose

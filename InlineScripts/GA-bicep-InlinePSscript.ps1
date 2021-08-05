# Read the GitHub Actions variables
[string]$githubWorkspace = "${{GITHUB.WORKSPACE}}"

# Read the environment variables in PowerShell
[string]$location = [System.Environment]::GetEnvironmentVariable('LOCATION')
[string]$bicepFile = [System.Environment]::GetEnvironmentVariable('BICEP_FILE')
[string]$resourcegroupName = [System.Environment]::GetEnvironmentVariable('RESOURCE_GROUP_NAME')

Write-Output ("* BICEP FILE: " + $($bicepFile))
Write-Output ("* RESOURCE GROUP NAME: " + $($resourcegroupName))
Write-Output ("* GITHUB_WORKSPACE: " + $($githubWorkspace))

$namePostFix = $resourcegroupName.Replace("rg-","")

## Create a Template Parameter Object (hashtable)
$objTemplateParameter = @{
  "location" = "$($location)";
  "workSpaceName" = "ws-$($namePostFix)";
  "hostpoolName" = "hp-$($namePostFix)";
  "appgroupName" = "ag-$($namePostFix)";
  "preferredAppGroupType" = "Desktop";
  "hostPoolType" = "pooled";
  "loadbalancertype" = "DepthFirst";
  "appgroupType" = "Desktop";
}
## Show objTemplateParameter
#$objTemplateParameter

# Location of the bicep file in the local checked-out repo
$biceptemplateFile = [string]("$($githubWorkspace)" + "\bicep\" + "$($bicepFile)")
Write-Output ("* BICEP TEMPLATE FILE: " + $($biceptemplateFile))

# Create the resourceGroup (if it does not yet exist)
if (!(Get-AzResourceGroup -Name $resourcegroupName -ErrorAction SilentlyContinue)) {
  New-AzResourceGroup -Name $resourcegroupName -Location $location
}

# ARM Template file
## Deploy resources based on bicep file for ARM Template
New-AzResourceGroupDeployment -ResourceGroupName $resourcegroupName -TemplateFile $($biceptemplateFile) -TemplateParameterObject $objTemplateParameter -Verbose

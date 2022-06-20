# $Name = 'DeployBicep' + (Get-Date -Format FileDateTime)
$Parameters = @{
    Name = 'DeployBicep' + (Get-Date -Format FileDateTime)
    ResourceGroupName = 'AzureFunctionsEnterprise'
    TemplateFile = '.\DeployFunction.bicep'
    functionName = 'GenerateStorageAccount01'
    versionTag = 'initial Function'
    isConsumptionPlan = $true
}
New-AzResourceGroupDeployment @Parameters -Verbose
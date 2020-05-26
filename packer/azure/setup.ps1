Connect-AzAccount

$context = Set-AzContext -Subscription "Visual Studio Professional"

$rgName = "rg-packer"
$imageName = "myWindowsServerImage"

# Create resource group to hold image
$location = "westeurope"
$rg = New-AzResourceGroup -Name $rgName -Location $location

# sort out service principal - use existing oen
$servicePrincipalCreds = Get-Credential -Message "Enter app id and service principal secret"

# get details for json file
$windowsJson = Get-Content .\windows.json | ConvertFrom-Json
$windowsJson.builders[0].managed_image_resource_group_name = $rgName
$windowsJson.builders[0].managed_image_name = $imageName

# Create temp json file
$windowsJson | ConvertTo-Json -Depth 5 -Compress| % { [System.Text.RegularExpressions.Regex]::Unescape($_) } | `
    Out-File -Encoding ascii .\temp.json

# invoke packer
& packer build -var "client_id=$($servicePrincipalCreds.UserName)" `
    -var "subscription_id=$($context.Subscription.Id)" `
    -var "tenant_id=$($context.Tenant.Id)" `
    -var "client_secret=$($servicePrincipalCreds.GetNetworkCredential().Password)" `
    .\temp.json

# Remove temp json file
remove-item .\temp.json



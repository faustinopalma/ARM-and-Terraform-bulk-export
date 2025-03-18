param([string]$TenantId = $null)  
  
# Import Azure module  
# Import-Module Az  
  
Write-Host "Connecting to Azure account..." -ForegroundColor Cyan  
# Connect to Azure account  
# Connect-AzAccount -UseDeviceAuthentication -TenantId $TenantId  
  
# Get a list of all Azure subscriptions  
Write-Host "Retrieving all subscriptions in the tenant..." -ForegroundColor Cyan  
if ($TenantId) {  
    $subscriptions = Get-AzSubscription -TenantId $TenantId  
} else {  
    $subscriptions = Get-AzSubscription  
}  
  
Write-Host "`nFound the following subscriptions:" -ForegroundColor Yellow  
$subscriptions | ForEach-Object {  
    Write-Host "Subscription Name: $($_.Name), Subscription ID: $($_.SubscriptionId)" -ForegroundColor White  
}  
  
# Loop through each subscription and register the Microsoft.AzureTerraform provider  
Write-Host "`nRegistering the provider Microsoft.AzureTerraform across subscriptions..." -ForegroundColor Green  
foreach ($subscription in $subscriptions) {  
    Write-Host "`nProcessing Subscription: $($subscription.Name), ID: $($subscription.SubscriptionId)" -ForegroundColor Yellow  
  
    try {  
        # Switch to the subscription context  
        Set-AzContext -SubscriptionId $subscription.SubscriptionId -TenantId $subscription.TenantId  
  
        # Register the provider  
        Register-AzResourceProvider -ProviderNamespace "Microsoft.AzureTerraform"  
        Write-Host "Successfully registered provider Microsoft.AzureTerraform for subscription: $($subscription.Name)" -ForegroundColor Green  
    } catch {  
        Write-Host "Failed to register provider Microsoft.AzureTerraform for subscription: $($subscription.Name)" -ForegroundColor Red  
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red  
    }  
}  
  
Write-Host "`nScript execution completed." -ForegroundColor Cyan  
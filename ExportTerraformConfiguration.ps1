param([string]$TenantId = $null)

# Import Azure module
# Import-Module Az

# Ensure Azure Terraform Resource Provider is registered
# az provider register -n Microsoft.AzureTerraform

# Connect to Azure account
# Connect-AzAccount -UseDeviceAuthentication -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Get the current timestamp for a unique folder name
$dateTimePostfix = (Get-Date).ToString("yyyy-MM-dd-HH-mm-ss")

# Define the "output" folder in the script directory
$outputFolder = Join-Path (Get-Location) "output"

# Ensure the "output" folder exists
if (!(Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Create a folder for the Terraform exports inside the "output" folder
$exportsFolder = Join-Path $outputFolder "terraform_exports-$dateTimePostfix"
New-Item -ItemType Directory -Path $exportsFolder | Out-Null
Write-Host "Terraform exports folder created inside 'output' at: $exportsFolder" -ForegroundColor Cyan

# Start transcript and save it inside the newly created folder
$transcriptPath = Join-Path $exportsFolder "ScriptTranscript.txt"
Start-Transcript -Path $transcriptPath -Append

# Get a list of all Azure subscriptions
if ($TenantId) {
    $subscriptions = Get-AzSubscription -TenantId $TenantId
} else {
    $subscriptions = Get-AzSubscription
}

# Loop through each subscription and retrieve resource groups
Write-Host "Listing all Azure subscriptions and exporting Terraform configurations:" -ForegroundColor Cyan
foreach ($subscription in $subscriptions) {
    # Display subscription info
    Write-Host "`nSubscription Name: $($subscription.Name), ID: $($subscription.SubscriptionId)" -ForegroundColor Yellow

    # Switch to the subscription context
    Set-AzContext -SubscriptionId $subscription.SubscriptionId -TenantId $subscription.TenantId

    # Retrieve all resource groups for the subscription
    $resourceGroups = Get-AzResourceGroup

    # Check if there are resource groups
    if ($resourceGroups.Count -eq 0) {
        Write-Host "No resource groups found in subscription: $($subscription.Name)" -ForegroundColor Red
    } else {
        # Create a folder for the subscription inside the "exports" folder
        $subscriptionFolder = Join-Path $exportsFolder $subscription.Name
        New-Item -ItemType Directory -Path $subscriptionFolder | Out-Null

        Write-Host "Exporting Terraform configurations for Resource Groups in Subscription:" -ForegroundColor Green
        foreach ($resourceGroup in $resourceGroups) {
            # Create a folder for the resource group inside the subscription folder
            $resourceGroupFolder = Join-Path $subscriptionFolder $resourceGroup.ResourceGroupName
            New-Item -ItemType Directory -Path $resourceGroupFolder | Out-Null

            Write-Host "  Resource Group: $($resourceGroup.ResourceGroupName)" -ForegroundColor White

            try {
                # Create an in-memory object for the Resource Group export
                $exportParameter = New-AzTerraformExportResourceGroupObject -ResourceGroupName $resourceGroup.ResourceGroupName

                # Execute the export command and get the result object
                $exportResult = Export-AzTerraform -ExportParameter $exportParameter

                # Extract the "Configuration" member from the result
                $terraformConfig = $exportResult.Configuration

                # Define the path for the Terraform configuration file
                $terraformFilePath = Join-Path $resourceGroupFolder "terraform_configuration.tf"

                # Save the configuration to a .tf file
                $terraformConfig | Out-File -FilePath $terraformFilePath -Encoding UTF8

                Write-Host "    Terraform configuration for resource group saved to: $terraformFilePath" -ForegroundColor Green
            } catch {
                Write-Host "    Failed to export Terraform configuration for resource group: $($resourceGroup.ResourceGroupName)" -ForegroundColor Red
                Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`nScript execution completed. Terraform configurations are saved in the folder: $exportsFolder" -ForegroundColor Cyan
Stop-Transcript
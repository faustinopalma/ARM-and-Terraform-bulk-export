param([string]$TenantId = $null)

# Helper function to split array into chunks
function Split-ArrayIntoChunks ($array, $chunkSize) {
    $result = @()
    for ($i = 0; $i -lt $array.Count; $i += $chunkSize) {
        $chunk = $array[$i..([math]::Min($i + $chunkSize - 1, $array.Count - 1))]
        $result += ,$chunk
    }
    return $result
}

# Ensure the Azure module is loaded
# Import-Module Az

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

# Create a "templates" folder with a unique postfix inside the "output" folder
$templatesFolder = Join-Path $outputFolder "templates-$dateTimePostfix"

New-Item -ItemType Directory -Path $templatesFolder | Out-Null
Write-Host "Templates folder created inside 'output' at: $templatesFolder" -ForegroundColor Cyan

# Start transcript and save it inside the newly created folder
$transcriptPath = Join-Path $templatesFolder "ScriptTranscript.txt"
Start-Transcript -Path $transcriptPath -Append

# Get a list of all Azure subscriptions
if ($TenantId) {
    $subscriptions = Get-AzSubscription -TenantId $TenantId
} else {
    $subscriptions = Get-AzSubscription
}

# Loop through each subscription and retrieve resource groups
Write-Host "Listing all Azure Subscriptions and exporting ARM Templates:" -ForegroundColor Cyan
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
        # Create a folder for the subscription inside the templates folder
        $subscriptionFolder = Join-Path $templatesFolder $subscription.Name
        New-Item -ItemType Directory -Path $subscriptionFolder | Out-Null

        Write-Host "Exporting ARM Templates for Resource Groups in Subscription:" -ForegroundColor Green
        foreach ($resourceGroup in $resourceGroups) {
            # Create a folder for the resource group inside the subscription folder
            $resourceGroupFolder = Join-Path $subscriptionFolder $resourceGroup.ResourceGroupName
            New-Item -ItemType Directory -Path $resourceGroupFolder | Out-Null

            Write-Host "  Resource Group: $($resourceGroup.ResourceGroupName)" -ForegroundColor White

            # Count the resources in the resource group
            $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
            $resourceCount = $resources.Count
            Write-Host "  Resource count: $resourceCount" -ForegroundColor Cyan

            if ($resourceCount -gt 200) {
                # Handle resource groups with more than 200 resources by exporting in chunks of 200 resources
                Write-Host "    Resource group has more than 200 resources. Exporting in batches of 200 resources." -ForegroundColor Yellow

                # Build an array with all ResourceIDs for the group
                $resourceIds = $resources | Select-Object -ExpandProperty ResourceId
                # Break the ResourceIds array into chunks of 200
                $chunks = Split-ArrayIntoChunks $resourceIds 200
                $batchIndex = 1
                foreach ($chunk in $chunks) {
                    try {
                        $batchTemplateFilePath = Join-Path $resourceGroupFolder "template-batch-$batchIndex.json"
                        # Export the current batch of resources
                        Export-AzResourceGroup -ResourceGroupName $resourceGroup.ResourceGroupName `
                                               -Resource $chunk `
                                               -Path $batchTemplateFilePath `
                                               -IncludeComments `
                                               -IncludeParameterDefaultValue
                        Write-Host "    Exported batch $batchIndex template for resource group. Saved to: $batchTemplateFilePath" -ForegroundColor Green
                        $batchIndex++
                    } catch {
                        Write-Host "    Failed to export batch $batchIndex for resource group: $($resourceGroup.ResourceGroupName)" -ForegroundColor Red
                        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            } else {
                # Handle resource groups with fewer than 200 resources by exporting as a single template
                try {
                    $templateFilePath = Join-Path $resourceGroupFolder "template.json"
                    Export-AzResourceGroup -ResourceGroupName $resourceGroup.ResourceGroupName `
                                           -Path $templateFilePath `
                                           -IncludeParameterDefaultValue `
                                           -IncludeComments
                    Write-Host "    ARM Template for resource group saved to: $templateFilePath" -ForegroundColor Green
                } catch {
                    Write-Host "    Failed to export ARM template for resource group: $($resourceGroup.ResourceGroupName)" -ForegroundColor Red
                    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

Write-Host "`nScript execution completed. Templates are saved in the folder: $templatesFolder" -ForegroundColor Cyan
Stop-Transcript
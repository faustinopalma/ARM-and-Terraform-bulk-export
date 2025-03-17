# Azure Automation Scripts: ARM Template & Terraform Exporter

Automate the export of Azure resources as ARM templates or Terraform configurations using these two PowerShell scripts. Perfect for backing up, replicating environments, or implementing Infrastructure-as-Code (IaC).

---

## What's Included?

1. **ARM Template Exporter (`ARM-Template-Exporter.ps1`)**
   - Exports ARM templates for all resource groups in your subscriptions.
   - Automatically splits large resource groups into chunks.
   - Saves templates in organized, timestamped folders.

2. **Terraform Configuration Exporter (`Terraform-Exporter.ps1`)**
   - Creates `.tf` files for Azure resource groups.
   - Saves configurations in a clear folder hierarchy by subscription and resource group.

---

## Why Use These Scripts?

- **Backup**: Save the current state of your Azure infrastructure.
- **Replication**: Easily replicate resources across subscriptions/tenants.
- **Transition to IaC**: Convert Azure resources into ARM templates or Terraform configurations.

---

## How to Use

### Prerequisites
- **PowerShell** installed on your machine.
- **Azure PowerShell Module (`Az`)**: Install by running:

  ```powershell
  Install-Module -Name Az -AllowClobber -Scope CurrentUser

  ## Running the Scripts  
  
### ARM Template Exporter  
1. Clone this repository.  
2. Open PowerShell and navigate to the script folder.  
3. Run the script:  
  
   ```powershell  
   .\ARM-Template-Exporter.ps1 -TenantId "<YourTenantId>"

   Replace `<YourTenantId>` with your Azure Tenant ID.    
If not specified, the script lists subscriptions from all accessible tenants.    
  
**Output**: Templates are saved in folders like `output/templates-<timestamp>`.    
  
---  
  
### Terraform Configuration Exporter  
1. Clone this repository.    
2. Open PowerShell and navigate to the script folder.    
3. Run the script:  
.\Terraform-Exporter.ps1 -TenantId "<YourTenantId>"  

Replace `<YourTenantId>` with your Azure Tenant ID.    
If not specified, the script lists subscriptions from all accessible tenants.    
  
**Output**: `.tf` files are saved in folders like `output/terraform_exports-<timestamp>`.    
  
---  
  
### Example Folder Structure  
  
Both scripts save outputs in timestamped folders under `output`. Example:  
output/  
├── templates-2023-10-05-15-45-00/  
│   ├── Subscription1/  
│   │   ├── ResourceGroup1/  
│   │   │   ├── template.json  
│   │   │   ├── template-batch-1.json  
│   │   └── ResourceGroup2/  
│   └── Subscription2/  
│       └── ResourceGroupA/  
├── terraform_exports-2023-10-05-15-45-00/  
│   ├── Subscription1/  
│   │   ├── ResourceGroup1/  
│   │   │   ├── terraform_configuration.tf  
│   │   └── ResourceGroup2/  
│   └── Subscription2/  
│       └── ResourceGroupA/  

### Notes  
- **Organized output**: Scripts save results in the `output` folder to keep things structured and avoid overwriting previous runs.  
- **Empty subscriptions**: Subscriptions without resource groups are skipped, and you'll receive a notification.  
  
---  
  
## License  
  
This project is licensed under the MIT License. You are free to use and modify it as needed.  
  
---  
  
## Feedback & Contributions  
  
Found an issue or have suggestions for improvement? Open an issue or submit a pull request. Contributions are always welcome!  
  
Enjoy automating your Azure exports!  
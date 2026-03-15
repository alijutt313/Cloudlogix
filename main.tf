terraform {
  # PHASE 1: THE VAULT (Remote State)
  # Keep this commented out for the first run! 
  # Once the Resource Group and Storage are built, you can migrate the state here.
  # backend "azurerm" {
  #   resource_group_name  = "DevOps-Final-RG"
  #   storage_account_name = "ststatefinal${random_string.suffix.result}" 
  #   container_name       = "tfstate"
  #   key                  = "terraform.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Update the Resource Group NAME and LOCATION
resource "azurerm_resource_group" "rg" {
  name     = "DevOps-Final-Deployment-RG" # Changed name to avoid the "already exists" error
  location = "East US 2"                 # Switched to a higher-capacity region
}
# 2. THE IDENTITY: Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 3. THE WAREHOUSE: Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "registry${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 4. THE SERVER: App Service Plan (Free Tier)
resource "azurerm_service_plan" "plan" {
  name                = "devops-free-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1" # Strictly $0.00/month
}

# 5. THE APPLICATION: Linux Web App
resource "azurerm_linux_web_app" "web_app" {
  name                = "webapp-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = false # Required for F1 Free Tier
    application_stack {
      docker_image_name   = "nginx:latest" # Placeholder until CI/CD push
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      
      # Correctly handling secrets natively within the stack block
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }
}

# OUTPUTS: Useful for your CI/CD pipeline
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "webapp_url" {
  value = azurerm_linux_web_app.web_app.default_hostname
}
output "suffix" {
  value = random_string.suffix.result
}
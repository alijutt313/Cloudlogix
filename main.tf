terraform {
  # PHASE 1: THE VAULT (Remote State)
  backend "azurerm" {
    resource_group_name  = "DevOps-Day3-RG"
    storage_account_name = "ststate1773215025" # Using the ID from your successful Day 2 run
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "rg" {
  name     = "DevOps-Day3-RG"
  location = "East US"
}

# PHASE 2: THE MULTI-APP DEPLOYMENT (Scaling)
resource "azurerm_container_group" "mega_app" {
  name                = "scaled-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "murtaza-scaled-app"

  # Instance 1
  container {
    name   = "app-instance-1"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld"
    cpu    = "0.5"
    memory = "1.0"
    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  # Instance 2 (Scaling)
  container {
    name   = "app-instance-2"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld"
    cpu    = "0.5"
    memory = "1.0"
    ports {
      port     = 81
      protocol = "TCP"
    }
  }
}

resource "random_string" "acr_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_container_registry" "acr" {
  name                = "registry${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Output the login server so we can use it in our pipeline
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
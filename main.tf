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

resource "random_string" "acr_name" {
  length  = 5
  special = false
  upper   = false
}

provider "azurerm" {
  features {}
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

# 1. The "Server" hardware (Free Tier)
resource "azurerm_service_plan" "app_plan" {
  name                = "devops-app-plan"
  resource_group_name = "DevOps-Day3-RG"
  location            = "East US"
  os_type             = "Linux"
  sku_name            = "F1" # Free Tier
}

# 2. The "Storefront" (The Web App)
resource "azurerm_linux_web_app" "web_app" {
  name                = "my-devops-site-${random_string.acr_name.result}"
  resource_group_name = "DevOps-Day3-RG"
  location            = "East US"
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    application_stack {
      docker_image_name   = "my-devops-app:latest"
      docker_registry_url = "https://registryfvq3o.azurecr.io"
    }
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://registryfvq3o.azurecr.io"
    "DOCKER_REGISTRY_SERVER_USERNAME" = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azurerm_container_registry.acr.admin_password
    "WEBSITES_PORT"                   = "80" # Tells Azure your container is listening on port 80
  }
}
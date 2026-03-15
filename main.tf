provider "azurerm" {
  features {}
}

# 1. New, fresh name to avoid "already exists" errors
resource "azurerm_resource_group" "rg" {
  name     = "DevOps-Final-Fresh-Start"
  location = "France Central" 
}

resource "azurerm_container_registry" "acr" {
  name                = "registryali${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_service_plan" "plan" {
  name                = "ali-free-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "ali-devops-app-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = false
    application_stack {
      docker_image_name   = "nginx:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "webapp_name" {
  value = azurerm_linux_web_app.webapp.name
}
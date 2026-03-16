provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "DevOps-Final-Fresh-Start"
  location = "France Central" 
}

# 2. Random Suffix for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# 3. Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "registryali${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 4. Log Analytics Workspace (The Database for logs)
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "ali-devops-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 5. Application Insights (The Monitoring Dashboard)
resource "azurerm_application_insights" "aai" {
  name                = "ali-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
}

# 6. Service Plan (Free Tier)
resource "azurerm_service_plan" "plan" {
  name                = "ali-free-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# 7. Linux Web App with Insights Connection
resource "azurerm_linux_web_app" "webapp" {
  name                = "ali-devops-app-final"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  # Connects the App to the Monitoring Dashboard
  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = azurerm_application_insights.aai.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  site_config {
    always_on = false
    application_stack {
      docker_image_name        = "nginx:latest"
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }
  }
}

# --- OUTPUTS ---

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "webapp_name" {
  value = azurerm_linux_web_app.webapp.name
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.aai.instrumentation_key
  sensitive = true
}
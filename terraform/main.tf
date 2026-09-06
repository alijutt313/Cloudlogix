provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "Project_1_3"
  location = "France Central" 
}

# 2. Random Suffix for unique naming
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_storage_account" "asa" {
  name                     = "stcloudlogix${random_string.random.result}" # Ensure valid storage account name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
  }
}

resource "azurerm_storage_container" "sc" {
  name                  = "$web"
  storage_account_name  = azurerm_storage_account.asa.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "asb" {
  name                   = "index.html"
  storage_container_id   = azurerm_storage_container.sc.id
  type                   = "Block"
  source_content         = "<h1>Cloudlogix API Live</h1>"
  content_type           = "text/html"
}



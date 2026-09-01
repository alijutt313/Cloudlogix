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
  name                     = "project1storageacc${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document = "index.html"
    error_404_document = "404.html" # Optional, but good practice
  }

}

resource "azurerm_storage_container" "asc" {
  name                  = "project1storagecontainer${random_string.suffix.result}"
  storage_account_id    = azurerm_storage_account.asa.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "asb" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.asa.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "index.html"
}



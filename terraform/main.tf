terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-cloudlogix-dev"
  location = "East US"
}

resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "asa" {
  name                     = "stcloudlogix${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "website" {
  storage_account_id = azurerm_storage_account.asa.id
  index_document     = "index.html"
}

data "azurerm_storage_container" "web_container" {
  name               = "$web"
  storage_account_id = azurerm_storage_account.asa.id
  depends_on         = [azurerm_storage_account_static_website.website]
}

resource "azurerm_storage_blob" "asb" {
  name                   = "index.html"
  storage_container_id   = data.azurerm_storage_container.web_container.id
  type                   = "Block"
  source_content         = "<h1>Cloudlogix API Live</h1>"
  content_type           = "text/html"
}
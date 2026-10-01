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

  backend "azurerm" {
    resource_group_name  = "rg-cloudlogix-dev"
    storage_account_name = "stcloudlogix3c815t"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

import {
  to = azurerm_resource_group.rg
  id = "/subscriptions/452040b1-48ac-463b-985f-f4dbd5e729a6/resourceGroups/rg-cloudlogix-dev"
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
  name                 = "index.html"
  storage_container_id = data.azurerm_storage_container.web_container.id
  type                 = "Block"
  source_content       = "Cloudlogix API Live"
  content_type         = "text/html"
}

output "static_website_url" {
value       = azurerm_storage_account.asa.primary_web_endpoint
description = "The public endpoint for the static website."
}
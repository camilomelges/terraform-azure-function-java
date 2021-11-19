terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.57.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "function_java" {
  name     = "functionsjavagroup"
  location = "Brazil South"
}

resource "azurerm_storage_account" "function_java" {
  name                     = "functionsjavaaccount"
  resource_group_name      = azurerm_resource_group.function_java.name
  location                 = azurerm_resource_group.function_java.location
  account_tier             = "Standard" # https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
  account_replication_type = "LRS"      # https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy
}

resource "azurerm_app_service_plan" "function_java" {
  name                = "functionsjavaplan"
  location            = azurerm_resource_group.function_java.location
  resource_group_name = azurerm_resource_group.function_java.name

  sku {
    tier = "Standard" # https://azure.microsoft.com/en-us/pricing/details/app-service/linux/
    size = "S1"       # https://azure.microsoft.com/en-us/pricing/details/app-service/linux/
  }
}

resource "azurerm_application_insights" "function_java" {
  name                = "terraformazurefunctionjava"
  location            = azurerm_resource_group.function_java.location
  resource_group_name = azurerm_resource_group.function_java.name
  application_type    = "java"
}

resource "azurerm_function_app" "function_java" {
  name                       = "terraformazurefunctionjava"
  location                   = azurerm_resource_group.function_java.location
  resource_group_name        = azurerm_resource_group.function_java.name
  app_service_plan_id        = azurerm_app_service_plan.function_java.id
  storage_account_name       = azurerm_storage_account.function_java.name
  storage_account_access_key = azurerm_storage_account.function_java.primary_access_key

  site_config {
    java_version = "11"
  }

  app_settings = {
    FUNCTION_WORKER_RUNTIME        = "java"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.function_java.instrumentation_key}"
  }
}

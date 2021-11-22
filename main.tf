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

variable "resource_group_name" {}
variable "storage_account_name" {}
variable "app_service_plan_name" {}
variable "application_insights_name" {}
variable "function_app_name" {}
variable "resource_group_location" {}

resource "azurerm_resource_group" "function_java" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_storage_account" "function_java" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.function_java.name
  location                 = azurerm_resource_group.function_java.location
  account_tier             = "Standard" # https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
  account_replication_type = "LRS"      # https://docs.microsoft.com/en-us/azure/storage/common/storage-redundancy
}

resource "azurerm_app_service_plan" "function_java" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.function_java.location
  resource_group_name = azurerm_resource_group.function_java.name

  sku {
    tier = "Standard" # https://azure.microsoft.com/en-us/pricing/details/app-service/linux/
    size = "S1"       # https://azure.microsoft.com/en-us/pricing/details/app-service/linux/
  }
}

resource "azurerm_application_insights" "function_java" {
  name                = var.application_insights_name
  location            = azurerm_resource_group.function_java.location
  resource_group_name = azurerm_resource_group.function_java.name
  application_type    = "java"
}

resource "azurerm_function_app" "function_java" {
  name                       = var.function_app_name
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

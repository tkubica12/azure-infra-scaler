// Get random string for suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  lower   = true
  number  = true
}

// Resource Group
resource "azurerm_resource_group" "scaler" {
  name     = var.resourceGroupName
  location = var.location
}


// Prepare storage account, container and token, upload code
resource "azurerm_storage_account" "scaler" {
  name                     = "scaler${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.scaler.name
  location                 = azurerm_resource_group.scaler.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "scaler_code_container" {
  name                  = "code"
  storage_account_name  = azurerm_storage_account.scaler.name
  container_access_type = "private"
}

data "azurerm_storage_account_sas" "storage_sas" {
  connection_string = azurerm_storage_account.scaler.primary_connection_string
  https_only        = false
  resource_types {
    service   = false
    container = false
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  start  = "2021-01-01"
  expiry = "2031-01-01"
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

resource "azurerm_storage_blob" "code" {
  name                   = "functions.zip"
  storage_account_name   = azurerm_storage_account.scaler.name
  storage_container_name = azurerm_storage_container.scaler_code_container.name
  type                   = "Block"
  source                 = "${path.root}/functions.zip"
}

// Create Azure Functions with monitoring
resource "azurerm_application_insights" "scaler" {
  name                = "scaler${random_string.suffix.result}"
  location            = azurerm_resource_group.scaler.location
  resource_group_name = azurerm_resource_group.scaler.name
  application_type    = "web"
}

resource "azurerm_app_service_plan" "scaler" {
  name                = "scaler-functions-plan"
  location            = azurerm_resource_group.scaler.location
  resource_group_name = azurerm_resource_group.scaler.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "scaler" {
  name                       = "scaler${random_string.suffix.result}"
  location                   = azurerm_resource_group.scaler.location
  resource_group_name        = azurerm_resource_group.scaler.name
  app_service_plan_id        = azurerm_app_service_plan.scaler.id
  storage_account_name       = azurerm_storage_account.scaler.name
  storage_account_access_key = azurerm_storage_account.scaler.primary_access_key
  version                    = "~3"
  identity {
    type = "SystemAssigned"
  }
  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY           = azurerm_application_insights.scaler.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME                 = "powershell"
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.scaler.primary_connection_string
    HASH                                     = base64encode(filesha256("${path.root}/functions.zip"))
    WEBSITE_RUN_FROM_PACKAGE                 = "${azurerm_storage_blob.code.url}${data.azurerm_storage_account_sas.storage_sas.sas}"
  }
}


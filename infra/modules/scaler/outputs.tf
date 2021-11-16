output "principalId" {
  value = azurerm_function_app.scaler.identity[0].principal_id
}

data "azurerm_function_app_host_keys" "scaler" {
  name                = azurerm_function_app.scaler.name
  resource_group_name = azurerm_resource_group.scaler.name
}

output "functionKey" {
  value = data.azurerm_function_app_host_keys.scaler.master_key
}

output "functionUrl" {
  value = azurerm_function_app.scaler.default_hostname
}
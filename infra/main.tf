// Scaler
module "scaler" {
  source            = "./modules/scaler"
  resourceGroupName = "scaler-rg"
  location          = "westeurope"
}

// RBAC for scaler
// TBD: custom role for least privilege
data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "example" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = module.scaler.principalId
}


// Testing VM
resource "azurerm_resource_group" "test" {
  name     = "scale-test-rg"
  location = "westeurope"
}

resource "azurerm_virtual_network" "test" {
  name                = "test-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "test" {
  name                = "test-nic"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "test" {
  name                = "test-machine"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  size                = "Standard_D4s_v3"
  admin_username      = "tomas"
  network_interface_ids = [
    azurerm_network_interface.test.id,
  ]

  admin_ssh_key {
    username   = "tomas"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  additional_capabilities {
    ultra_ssd_enabled = true
  }

  zone = 3
}

resource "azurerm_managed_disk" "premium1" {
  name                 = "premium-disk1"
  location             = azurerm_resource_group.test.location
  resource_group_name  = azurerm_resource_group.test.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  zones                = ["3"]
}

resource "azurerm_managed_disk" "premium2" {
  name                 = "premium-disk2"
  location             = azurerm_resource_group.test.location
  resource_group_name  = azurerm_resource_group.test.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  zones                = ["3"]
}

resource "azurerm_managed_disk" "ultra1" {
  name                 = "ultra-disk1"
  location             = azurerm_resource_group.test.location
  resource_group_name  = azurerm_resource_group.test.name
  storage_account_type = "UltraSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  disk_iops_read_write = 1024
  disk_mbps_read_write = 10
  zones                = ["3"]
}

resource "azurerm_managed_disk" "ultra2" {
  name                 = "ultra-disk2"
  location             = azurerm_resource_group.test.location
  resource_group_name  = azurerm_resource_group.test.name
  storage_account_type = "UltraSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  disk_iops_read_write = 1024
  disk_mbps_read_write = 10
  zones                = ["3"]
}

resource "azurerm_virtual_machine_data_disk_attachment" "premium1" {
  managed_disk_id    = azurerm_managed_disk.premium1.id
  virtual_machine_id = azurerm_linux_virtual_machine.test.id
  lun                = "1"
  caching            = "ReadOnly"
}

resource "azurerm_virtual_machine_data_disk_attachment" "premium2" {
  managed_disk_id    = azurerm_managed_disk.premium2.id
  virtual_machine_id = azurerm_linux_virtual_machine.test.id
  lun                = "2"
  caching            = "ReadOnly"
}

resource "azurerm_virtual_machine_data_disk_attachment" "ultra1" {
  managed_disk_id    = azurerm_managed_disk.ultra1.id
  virtual_machine_id = azurerm_linux_virtual_machine.test.id
  lun                = "3"
  caching            = "None"
}

resource "azurerm_virtual_machine_data_disk_attachment" "ultra2" {
  managed_disk_id    = azurerm_managed_disk.ultra2.id
  virtual_machine_id = azurerm_linux_virtual_machine.test.id
  lun                = "4"
  caching            = "None"
}

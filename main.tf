provider "azurerm" {
    version = "2.2.0"
    features {}
}

resource "azurerm_resource_group" "testehp8_rg" {
    name = var.testehp8_rg
    location = var.testehp8_location
}

/*resource "azurerm_virtual_network" "oztestehp8_vnet" {
  name = "${var.resource_prefix}-vnet"
  location = var.testehp8_location
  resource_group_name = azurerm_resource_group.testehp8_rg.name
  address_space = [var.testehp8_address_space]
}*/

/*resource "azurerm_subnet" "oztestehp8_subnet" {
  name = "${var.resource_prefix}-subnet"
  resource_group_name = azurerm_resource_group.testehp8_rg.name
  virtual_network_name = azurerm_virtual_network.oztestehp8_vnet.name
  address_prefix = var.testehp8_address_prefix
}*/

resource "azurerm_network_interface" "testehp8_nic" {
  name = "${var.testehp8_name}-nic"
  location = var.testehp8_location
  resource_group_name = azurerm_resource_group.testehp8_rg.name

  /*ip_configuration {
    name = "${var.testehp8_name}-ip"
    subnet_id = azurerm_subnet.oztestehp8_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = azurerm_public_ip.testehp8_public_ip.id
  }*/

    ip_configuration {

    name                          = "internal"

    subnet_id                     = "/subscriptions/b683882d-5be0-4948-b46b-b2e9ac036d0b/resourceGroups/ITC-Lab-Network-uswest2-RG/providers/Microsoft.Network/virtualNetworks/itc-sap-usw2-VNet/subnets/itc-saplab-subnet"


    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.testehp8_public_ip.id

  }
}

resource "azurerm_public_ip" "testehp8_public_ip" {
  name = "${var.resource_prefix}-public-ip"
  location = var.testehp8_location
  resource_group_name = azurerm_resource_group.testehp8_rg.name
  allocation_method = var.environment == "production" ? "Static" : "Dynamic"
}

resource "azurerm_network_security_group" "testehp8_nsg" {
  name = "${var.resource_prefix}-nsg"
  location = var.testehp8_location
  resource_group_name = azurerm_resource_group.testehp8_rg.name
}

resource "azurerm_network_security_rule" "testehp8_nsg_rule_rdp" {
  name = "RDP Inbound"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "3389"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.testehp8_rg.name
  network_security_group_name = azurerm_network_security_group.testehp8_nsg.name
}

resource "azurerm_network_interface_security_group_association" "testehp8_nsg_association" {
  network_security_group_id = azurerm_network_security_group.testehp8_nsg.id
  network_interface_id = azurerm_network_interface.testehp8_nic.id
}

resource "azurerm_windows_virtual_machine" "testehp8" {
  name = var.testehp8_name
  location = var.testehp8_location
  resource_group_name = azurerm_resource_group.testehp8_rg.name
  network_interface_ids = [azurerm_network_interface.testehp8_nic.id]
  size = "Standard_B4ms"
  admin_username = "testuser"
  admin_password = "Oz$oft2021@*"

  os_disk {
      caching = "ReadWrite"
      storage_account_type = "StandardSSD_LRS"
  }

source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2019-datacenter-gensecond"
    version = "latest"
}

}
resource "azurerm_managed_disk" "testehp8_managed_disk" {
  name                 = "${var.testehp8_name}-DataDisk_0"
  location             = var.testehp8_location
  resource_group_name  = azurerm_resource_group.testehp8_rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 500
}

resource "azurerm_virtual_machine_data_disk_attachment" "testehp8_data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.testehp8_managed_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.testehp8.id
  lun                = "0"
  caching            = "ReadWrite"
}
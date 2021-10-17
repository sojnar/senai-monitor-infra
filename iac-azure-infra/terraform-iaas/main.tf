provider "azurerm" {
    features {}

}

resource "azurerm_resource_group" "rg" {
    name                 = "rg-${var.name-network}"
    location             = var.name-location
        tags = {
          environment    = "Produto"
          team           = "DevOps"
        }
}

resource "azurerm_virtual_network" "vnet" {
    name                    = var.name-network
    address_space           = ["172.17.0.0/16"]
    location                = var.name-location
    resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name                    = "internal-sub-${var.name-network}"
    resource_group_name     = azurerm_resource_group.rg.name
    virtual_network_name    = azurerm_virtual_network.vnet.name
    address_prefixes          = ["172.17.0.0/24"] 
}

resource "azurerm_public_ip" "public-ip" {
    name            = "ip-publico-${var.name-virtualmachine}" 
    location        = var.name-location
    resource_group_name = azurerm_resource_group.rg.name
    domain_name_label   = "dns1-${var.name-virtualmachine}" 
    allocation_method = "Static"
}

resource "azurerm_network_security_group" "nsg" {
    name            = "vm01-nsg1-${var.name-network}"
    location        = var.name-location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name            = "SSH-HTTP"
        priority        = 1001
        direction       = "Inbound"
        access          = "Allow"
        protocol        = "tcp"
        source_port_range   = "*"
        destination_port_ranges  = [9000,9200,5601,9090,3031,22,80,8084,8081]
        source_address_prefix   = "*"
        destination_address_prefix  ="*"
    }
}

resource "azurerm_network_interface" "nic" {
    name            = "vm01-ni-${var.name-virtualmachine}-${var.name-network}"
    location        = var.name-location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name        = "vm01-niconfig-${var.name-virtualmachine}-${var.name-network}"
        subnet_id   = azurerm_subnet.subnet.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id =  azurerm_public_ip.public-ip.id
    }
}

resource "azurerm_virtual_machine" "vm" {
    name            = var.name-virtualmachine
    location        = var.name-location
    resource_group_name     =  azurerm_resource_group.rg.name
    network_interface_ids   =  [azurerm_network_interface.nic.id]
    vm_size                 =  "Standard_B1s"

    

    storage_os_disk {
        name        = "vm01-osdisk"
        caching     = "ReadWrite"
        create_option   = "FromImage"
        managed_disk_type   = "Premium_LRS"
    }

    storage_image_reference {
        publisher   =   "Canonical"
        offer       =   "UbuntuServer"
        sku         =   "16.04.0-LTS"
        version     =   "latest"
    }

    os_profile {
        computer_name   =   "vm01"
        admin_username  =   "sojnar"
    }

    os_profile_linux_config {
        disable_password_authentication  = true

        ssh_keys {
          path      =  "/home/sojnar/.ssh/authorized_keys"
          key_data  =  file("/var/jenkins_home/.ssh/id_rsa.pub")
        }
    }
}
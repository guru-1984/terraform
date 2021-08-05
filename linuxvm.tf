#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
# Create a Linux VM 
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*

#
# - Provider Block
#

provider "azurerm" {

    client_id       =   var.client_id
    client_secret   =   var.client_secret
    subscription_id =   var.subscription_id
    tenant_id       =   var.tenant_id
  
    features {}
}

#
# - Create a Resource Group
#

resource "azurerm_resource_group" "rg" {
    name                  =   "${var.prefix}-rg"
    location              =   var.location
    tags                  =   var.tags
}

#
# - Create a Virtual Network
#

resource "azurerm_virtual_network" "vnet" {
    name                  =   "${var.prefix}-vnet"
    resource_group_name   =   azurerm_resource_group.rg.name
    location              =   azurerm_resource_group.rg.location
    address_space         =   [var.vnet_address_range]
    tags                  =   var.tags
}

#
# - Create a Subnet inside the virtual network
#

resource "azurerm_subnet" "web" {
    name                  =   "${var.prefix}-web-subnet"
    resource_group_name   =   azurerm_resource_group.rg.name
    virtual_network_name  =   azurerm_virtual_network.vnet.name
    address_prefixes      =   [var.subnet_address_range]
}

#
# - Create a Network Security Group
#

resource "azurerm_network_security_group" "nsg" {
    name                        =       "${var.prefix}-web-nsg"
    resource_group_name         =       azurerm_resource_group.rg.name
    location                    =       azurerm_resource_group.rg.location
    tags                        =       var.tags

    security_rule {
    name                        =       "Allow_all"
    priority                    =       100
    direction                   =       "Inbound"
    access                      =       "Allow"
    protocol                    =       "tcp"
    source_port_range           =       "*"
    destination_port_range      =       "*"
    source_address_prefix       =       "*" 
    destination_address_prefix  =       "*"
    
    }

}


#
# - Subnet-NSG Association
#

resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
    subnet_id                    =       azurerm_subnet.web.id
    network_security_group_id    =       azurerm_network_security_group.nsg.id
}


#
# - Public IP (To Login to Linux VM)
#

resource "azurerm_public_ip" "pip" {
    count = var.vmcount
    name                            =     "${var.prefix}-linuxvm-public-ip-${count.index}"
    resource_group_name             =     azurerm_resource_group.rg.name
    location                        =     azurerm_resource_group.rg.location
    allocation_method               =     var.allocation_method[0]
    tags                            =     var.tags
}

#
# - Create a Network Interface Card for Virtual Machine
#

resource "azurerm_network_interface" "nic" {
    count = var.vmcount
    name                              =   "${var.prefix}-linuxvm-nic-${count.index}"
    resource_group_name               =   azurerm_resource_group.rg.name
    location                          =   azurerm_resource_group.rg.location
    tags                              =   var.tags
    ip_configuration                  {
        name                          =  "internal"
        subnet_id                     =   azurerm_subnet.web.id
        public_ip_address_id          =   element(azurerm_public_ip.pip.*.id, count.index)
        private_ip_address_allocation =   var.allocation_method[1]
    }
}


#
# - Create a Linux Virtual Machine
# 

resource "azurerm_linux_virtual_machine" "vm" {
    count = var.vmcount
    name                              =   "${var.prefix}-linux-${count.index}"
    resource_group_name               =   azurerm_resource_group.rg.name
    location                          =   azurerm_resource_group.rg.location
    network_interface_ids = [
    element(azurerm_network_interface.nic.*.id, count.index)
,
  ]
    size                              =   var.virtual_machine_size
    admin_username                    =   var.admin_username
    admin_password                    =   var.admin_password
    disable_password_authentication   =   false

    os_disk  {
        caching                       =   var.os_disk_caching
        storage_account_type          =   var.os_disk_storage_account_type
        disk_size_gb                  =   var.os_disk_size_gb
    }

    source_image_reference {
        publisher                     =   var.publisher
        offer                         =   var.offer
        sku                           =   var.sku
        version                       =   var.vm_image_version
    }
    tags                              =   var.tags
}
resource "null_resource" "linuxn" {
    //depend_on = []
  connection {
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
	  host = "${azurerm_public_ip.pip[0].ip_address}"
      type  = "ssh"
      port = "22"
   }
    provisioner "file" {
     source      = "master.sh"
     destination = "/home/guru/master.sh"
    }

    provisioner "remote-exec" {
     inline = [
      "sudo apt-get update -y" ,
      "chmod +x /home/guru/master.sh",
      "/home/guru/master.sh ",
     ]
    }
}
resource "null_resource" "node2" {
    //depend_on = []
  connection {
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
	  host = "${azurerm_public_ip.pip[1].ip_address}"
      type  = "ssh"
      port = "22"
   }
  
    provisioner "file" {
     source      = "node.sh"
     destination = "/home/guru/node.sh"
    }

    provisioner "remote-exec" {
     inline = [
      "sudo apt-get update -y" ,
      "chmod +x /home/guru/node.sh",
      "/home/guru/node.sh ",
     ]
    }
}


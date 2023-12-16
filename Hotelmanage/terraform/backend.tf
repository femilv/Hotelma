terraform{
    backend "azurerm"{
        resource_group_name  = "terraform-staorage-rg"
        storage_account_name = "terraformstoragesep"
        container_name       = "terrasepcontainer"
        key                  = "terraform.tfstate"
    }
}
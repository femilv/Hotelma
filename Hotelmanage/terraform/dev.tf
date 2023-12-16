provider "azurerm" {
  # Ensure that you have the required version specified 
  # and features block if needed based on the provider version.
}

resource "azurerm_resource_group" "dev" {
  name     = var.azure["resource_group_name"]
  location = var.azure["location"]

  tags = {
    environment = "DEV"
    created-by  = "Terraform"
  }
}

resource "azurerm_service_plan" "dev" {
  name                = var.azure["resource_name"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  sku_name = "B1"  # Ensure this is a valid SKU for your subscription

  # Removed the 'kind' and 'reserved' attributes
}

  # The os_type argument specifies the operating system of the service plan.
  os_type = "Linux" # Set to "Linux" or "Windows" depending on your requirements.
}

resource "azurerm_app_service" "dev" {
  name                = var.azure["resource_name"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  app_service_plan_id = azurerm_service_plan.dev.id

  site_config {
    always_on                = true
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
    linux_fx_version         = "DOCKER|${var.acr["host"]}/${var.acr["repository"]}:${var.acr["tag"]}"
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL      = "https://${var.acr["host"]}"
    DOCKER_REGISTRY_SERVER_USERNAME = var.acr["username"]
    DOCKER_REGISTRY_SERVER_PASSWORD = var.acr["password"]
    SPRING_DATASOURCE_URL           = "jdbc:mysql://${var.azure["resource_name"]}.mysql.database.azure.com:3306/${var.mysql["database"]}?verifyServerCertificate=true&useSSL=true&requireSSL=false"
    SPRING_DATASOURCE_USERNAME      = "${var.mysql["username"]}@${var.azure["resource_name"]}"
    SPRING_DATASOURCE_PASSWORD      = var.mysql["password"]
  }
}

resource "azurerm_mysql_server" "dev" {
  name                = var.azure["resource_name"]
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name

  sku_name = "B_Gen5_1"
  storage_mb = 5120
  backup_retention_days = 7

  administrator_login          = var.mysql["username"]
  administrator_login_password = var.mysql["password"]
  version                      = "5.7"
  ssl_enforcement_enabled      = false
}

resource "azurerm_mysql_database" "db" {
  name                = var.mysql["database"]
  resource_group_name = azurerm_resource_group.dev.name
  server_name         = azurerm_mysql_server.dev.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "azure" {
  name                = "AllowAllWindowsAzureIps"
  resource_group_name = azurerm_resource_group.dev.name
  server_name         = azurerm_mysql_server.dev.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_firewall_rule" "all" {
  name                = "all"
  resource_group_name = azurerm_resource_group.dev.name
  server_name         = azurerm_mysql_server.dev.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

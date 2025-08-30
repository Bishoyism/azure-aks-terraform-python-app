resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-microservices-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-microservices-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-microservices"
  sku_tier            = "Free"  # Explicitly set free tier

  # Explicit dependency
  depends_on = [azurerm_resource_group.aks_rg]

  default_node_pool {
    name                = "default"
    node_count          = 1  # Fixed node count
    vm_size             = "Standard_B2s"
    enable_auto_scaling = false  # Explicitly disable autoscaling
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "bishoyflaskregistry" # Must be globally unique
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Basic"  # Free tier not available for ACR
  admin_enabled       = true
}

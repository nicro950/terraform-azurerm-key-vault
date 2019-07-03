locals {
  access_policies = [
    for p in var.access_policies : merge({
      group_names             = []
      object_ids              = []
      user_principal_names    = []
      certificate_permissions = []
      key_permissions         = []
      secret_permissions      = []
      storage_permissions     = []
    }, p)
  ]

  group_names          = distinct(flatten(local.access_policies[*].group_names))
  user_principal_names = distinct(flatten(local.access_policies[*].user_principal_names))

  group_object_ids = { for g in data.azuread_group.main : lower(g.name) => g.id }
  user_object_ids  = { for u in data.azuread_user.main : lower(u.user_principal_name) => u.id }

  flattened_access_policies = concat(
    flatten([
      for p in local.access_policies : flatten([
        for i in p.object_ids : {
          object_id               = i
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ]),
    flatten([
      for p in local.access_policies : flatten([
        for n in p.group_names : {
          object_id               = local.group_object_ids[lower(n)]
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ]),
    flatten([
      for p in local.access_policies : flatten([
        for n in p.user_principal_names : {
          object_id               = local.user_object_ids[lower(n)]
          certificate_permissions = p.certificate_permissions
          key_permissions         = p.key_permissions
          secret_permissions      = p.secret_permissions
          storage_permissions     = p.storage_permissions
        }
      ])
    ])
  )

  grouped_access_policies = { for p in local.flattened_access_policies : p.object_id => p... }

  combined_access_policies = [
    for k, v in local.grouped_access_policies : {
      object_id               = k
      certificate_permissions = distinct(flatten(v[*].certificate_permissions))
      key_permissions         = distinct(flatten(v[*].key_permissions))
      secret_permissions      = distinct(flatten(v[*].secret_permissions))
      storage_permissions     = distinct(flatten(v[*].storage_permissions))
    }
  ]

  service_principal_object_id = data.azurerm_client_config.main.service_principal_object_id
}

data "azuread_group" "main" {
  count = length(local.group_names)
  name  = local.group_names[count.index]
}

data "azuread_user" "main" {
  count               = length(local.user_principal_names)
  user_principal_name = local.user_principal_names[count.index]
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "main" {}

resource "azurerm_key_vault" "main" {
  name                = var.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.main.tenant_id

  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment

  sku {
    name = var.sku
  }

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "main" {
  count        = length(local.combined_access_policies)
  key_vault_id = azurerm_key_vault.main.id

  tenant_id = data.azurerm_client_config.main.tenant_id
  object_id = local.combined_access_policies[count.index].object_id

  certificate_permissions = local.combined_access_policies[count.index].certificate_permissions
  key_permissions         = local.combined_access_policies[count.index].key_permissions
  secret_permissions      = local.combined_access_policies[count.index].secret_permissions
  storage_permissions     = local.combined_access_policies[count.index].storage_permissions
}

resource "azurerm_key_vault_secret" "main" {
  count        = length(var.secrets)
  name         = var.secrets[count.index].name
  value        = var.secrets[count.index].value
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_key_vault_access_policy.main]
}

resource "azurerm_key_vault_access_policy" "self" {
  count        = local.service_principal_object_id != "" ? 1 : 0
  key_vault_id = azurerm_key_vault.main.id

  tenant_id = data.azurerm_client_config.main.tenant_id
  object_id = local.service_principal_object_id

  key_permissions    = ["create", "delete", "get"]
  secret_permissions = ["delete", "get", "set"]
}

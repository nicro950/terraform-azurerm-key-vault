locals {
  access_policies = [
    for policy in var.access_policies : merge({
      group_names             = []
      object_ids              = []
      user_principal_names    = []
      certificate_permissions = []
      key_permissions         = []
      secret_permissions      = []
      storage_permissions     = []
    }, policy)
  ]

  flattened_access_policies = flatten([
    for policy in local.access_policies : flatten([
      for id in policy.object_ids : {
        object_id               = id
        certificate_permissions = tolist(policy.certificate_permissions)
        key_permissions         = tolist(policy.key_permissions)
        secret_permissions      = tolist(policy.secret_permissions)
        storage_permissions     = tolist(policy.storage_permissions)
      }
    ]) if policy.object_ids != []
  ])

  flattened_group_access_policies = flatten([
    for policy in local.access_policies : flatten([
      for name in policy.group_names : {
        group_name              = lower(name)
        certificate_permissions = tolist(policy.certificate_permissions)
        key_permissions         = tolist(policy.key_permissions)
        secret_permissions      = tolist(policy.secret_permissions)
        storage_permissions     = tolist(policy.storage_permissions)
      }
    ]) if policy.group_names != []
  ])

  flattened_user_access_policies = flatten([
    for policy in local.access_policies : flatten([
      for name in policy.user_principal_names : {
        user_principal_name     = lower(name)
        certificate_permissions = tolist(policy.certificate_permissions)
        key_permissions         = tolist(policy.key_permissions)
        secret_permissions      = tolist(policy.secret_permissions)
        storage_permissions     = tolist(policy.storage_permissions)
      }
    ]) if policy.user_principal_names != []
  ])

  grouped_group_access_policies = {
    for policy in local.flattened_group_access_policies :
    policy.group_name => policy ...
  }

  grouped_user_access_policies = {
    for policy in local.flattened_user_access_policies :
    policy.user_principal_name => policy ...
  }

  group_names          = keys(local.grouped_group_access_policies)
  user_principal_names = keys(local.grouped_user_access_policies)

  group_object_ids = {
    for group in data.azuread_group.main :
    lower(group.name) => group.id
  }

  user_object_ids = {
    for user in data.azuread_user.main :
    lower(user.user_principal_name) => user.id
  }

  group_access_policies = [
    for name, policies in local.grouped_group_access_policies : {
      object_id = local.group_object_ids[name]
      certificate_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.certificate_permissions
        ]) if length(policy.certificate_permissions) > 0
      ]))
      key_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.key_permissions
        ]) if length(policy.key_permissions) > 0
      ]))
      secret_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.secret_permissions
        ]) if length(policy.secret_permissions) > 0
      ]))
      storage_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.storage_permissions
        ]) if length(policy.storage_permissions) > 0
      ]))
    }
  ]

  user_access_policies = [
    for name, policies in local.grouped_user_access_policies : {
      object_id = local.user_object_ids[name]
      certificate_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.certificate_permissions
        ]) if length(policy.certificate_permissions) > 0
      ]))
      key_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.key_permissions
        ]) if length(policy.key_permissions) > 0
      ]))
      secret_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.secret_permissions
        ]) if length(policy.secret_permissions) > 0
      ]))
      storage_permissions = toset(flatten([
        for policy in policies : flatten([
          policy.storage_permissions
        ]) if length(policy.storage_permissions) > 0
      ]))
    }
  ]
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
  count               = length(local.flattened_access_policies)
  vault_name          = azurerm_key_vault.main.name
  resource_group_name = azurerm_key_vault.main.resource_group_name

  tenant_id = data.azurerm_client_config.main.tenant_id
  object_id = local.flattened_access_policies[count.index].object_id

  certificate_permissions = local.flattened_access_policies[count.index].certificate_permissions
  key_permissions         = local.flattened_access_policies[count.index].key_permissions
  secret_permissions      = local.flattened_access_policies[count.index].secret_permissions
  storage_permissions     = local.flattened_access_policies[count.index].storage_permissions
}

resource "azurerm_key_vault_access_policy" "group" {
  count               = length(local.group_access_policies)
  vault_name          = azurerm_key_vault.main.name
  resource_group_name = azurerm_key_vault.main.resource_group_name

  tenant_id = data.azurerm_client_config.main.tenant_id
  object_id = local.group_access_policies[count.index].object_id

  certificate_permissions = local.group_access_policies[count.index].certificate_permissions
  key_permissions         = local.group_access_policies[count.index].key_permissions
  secret_permissions      = local.group_access_policies[count.index].secret_permissions
  storage_permissions     = local.group_access_policies[count.index].storage_permissions
}

resource "azurerm_key_vault_access_policy" "user" {
  count               = length(local.user_access_policies)
  vault_name          = azurerm_key_vault.main.name
  resource_group_name = azurerm_key_vault.main.resource_group_name

  tenant_id = data.azurerm_client_config.main.tenant_id
  object_id = local.user_access_policies[count.index].object_id

  certificate_permissions = local.user_access_policies[count.index].certificate_permissions
  key_permissions         = local.user_access_policies[count.index].key_permissions
  secret_permissions      = local.user_access_policies[count.index].secret_permissions
  storage_permissions     = local.user_access_policies[count.index].storage_permissions
}

resource "azurerm_key_vault_secret" "main" {
  count        = length(var.secrets)
  name         = var.secrets[count.index].name
  value        = var.secrets[count.index].value
  key_vault_id = azurerm_key_vault.main.id
}

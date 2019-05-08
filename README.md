# Key Vault

Create Key Vault in Azure.

## Example Usage

```hcl
resource "azurerm_resource_group" "main" {
  name     = "example-resources"
  location = "westeurope"
}

module "key_vault" {
  source = "innovationnorway/key-vault/azurerm"

  name = "example-vault"

  resource_group_name = azurerm_resource_group.main.name

  access_policies = [
    {
     user_principal_names = ["user@example.com"]
     secret_permissions   = ["get", "list"]
    },
    {
     group_names        = ["developers", "engineers"]
     secret_permissions = ["get", "list", "set"]
    },
  ]

  secrets = [
    {
      name  = "secure-message"
      value = "Hello, world!"
    }
  ]
}
```

## Arguments

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the Key Vault. |
| `resource_group_name` | `string` | The name of an existing resource group for the Key Vault. |
| `sku` | `string` | The name of the SKU used for the Key Vault. The options are: `standard`, `premium`. Default: `standard`. |
| `enabled_for_deployment` | `bool` | Allow Virtual Machines to retrieve certificates stored as secrets from the Key Vault. Default: `false`. |
| `enabled_for_disk_encryption` | `bool` | Allow Disk Encryption to retrieve secrets from the vault and unwrap keys. Default: `false`. |
| `enabled_for_template_deployment` | `bool` | Allow Resource Manager to retrieve secrets from the Key Vault. Default: `false`. |
| `access_policies` | `list` | List of access policies for the Key Vault. |
| `secrets` | `list` | List of secrets for Key Vault. |
| `tags` | `map` | A mapping of tags to assign to the resource. |

The `access_policies` object can have the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `group_names` | `list` | List of names of Azure AD groups. |
| `object_ids` | `list` | List of object IDs of Azure AD users, security groups or service principals. |
| `user_principal_names` | `list` | List of user principal names of Azure AD users. |
| `certificate_permissions` | `list` |  List of certificate permissions. The options are: `backup`, `create`, `delete`, `deleteissuers`, `get`, `getissuers`, `import`, `list`, `listissuers`, `managecontacts`, `manageissuers`, `purge`, `recover`, `restore`, `setissuers` and `update`. |
| `key_permissions` | `list` | List of key permissions. The options are: `backup`, `create`, `decrypt`, `delete`, `encrypt`, `get`, `import`, `list`, `purge`, `recover`, `restore`, `sign`, `unwrapkey`, `update`, `verify` and `wrapkey`. |
| `secret_permissions` | `list` | List of secret permissions. The options are: `backup`, `delete`, `get`, `list`, `purge`, `recover`, `restore` and `set`. |
| `storage_permissions` | `list` | List of storage permissions. The options are: `backup`, `delete`, `deletesas`, `get`, `getsas`, `list`, `listsas`, `purge`, `recover`, `regeneratekey`, `restore`, `set`, `setsas` and `update`. |

The `secrets` object can have the following keys:

| Name | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the secret. |
| `value` | `string` | The value of the secret. |


## Limitations

Due to current limitations of the Terraform language, items added or removed from the `access_policies` and `secrets` lists, will also update subsequent items with indexes greater than where the addition or removal was made. 

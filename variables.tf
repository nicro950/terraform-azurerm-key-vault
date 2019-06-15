variable "name" {
  type        = string
  description = "The name of the Key Vault."
}

variable "resource_group_name" {
  type        = string
  description = "The name of an existing resource group for the Key Vault."
}

variable "sku" {
  type        = string
  description = "The name of the SKU used for the Key Vault. The options are: `standard`, `premium`."
  default     = "standard"
}

variable "enabled_for_deployment" {
  type        = bool
  description = "Allow Virtual Machines to retrieve certificates stored as secrets from the key vault."
  default     = false
}

variable "enabled_for_disk_encryption" {
  type        = bool
  description = "Allow Disk Encryption to retrieve secrets from the vault and unwrap keys."
  default     = false
}

variable "enabled_for_template_deployment" {
  type        = bool
  description = "Allow Resource Manager to retrieve secrets from the key vault."
  default     = false
}

variable "access_policies" {
  type        = any
  description = "List of access policies for the Key Vault."
  default     = []
}

variable "secrets" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "List of secrets for the Key Vault."
  default     = []
}

variable "tags" {
  type        = map
  description = "A mapping of tags to assign to the resources."
  default     = {}
}

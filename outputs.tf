output "id" {
  value       = azurerm_key_vault.main.id
  description = "The ID of the Key Vault."
}

output "uri" {
  value       = azurerm_key_vault.main.vault_uri
  description = "The URI of the Key Vault."
}

output "secrets" {
  value       = { for s in azurerm_key_vault_secret.main : s.name => s.id }
  description = "A mapping of secret names and URIs."
}

output "references" {
  value = {
    for s in azurerm_key_vault_secret.main :
    s.name => format("@Microsoft.KeyVault(SecretUri=%s)", s.id)
  }
  description = "A mapping of Key Vault references for App Service and Azure Functions."
}

/*
data "azurerm_billing_mca_account_scope" "main" {
  provider = azurerm.owner

  // The value for this is billing_account_id
  billing_account_name = var.sample_subscription.billing_account_id
  
  // The value for this is billing_profile_id
  billing_profile_name = var.sample_subscription.billing_profile_id

  // The value for this is the invoice section id
  invoice_section_name = var.invoice_section_id
}

resource "azurerm_subscription" "main" {
  provider = azurerm.owner

  billing_scope_id  = data.azurerm_billing_mca_account_scope.main.id
  subscription_name = var.sample_subscription.name
}
*/

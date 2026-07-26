variable "primary_region" {
  description = "Region holding the workloads and the primary vault."
  type        = string
  default     = "eu-central-1"
}

variable "replica_region" {
  description = "Region receiving the cross-region copies."
  type        = string
  default     = "eu-west-1"
}

variable "source_account_id" {
  description = "Account owning the workloads and running the backup jobs."
  type        = string
}

variable "vault_account_id" {
  description = "Dedicated backup account receiving the cross-account copies."
  type        = string
}

variable "vault_account_role_arn" {
  description = "Role in the backup account that Terraform assumes to create the vault there."
  type        = string
}

variable "owner_tag_value" {
  description = "Value required on the Owner tag for a resource to be selected."
  type        = string
}

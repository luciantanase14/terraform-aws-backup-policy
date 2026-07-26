output "plan_id" {
  description = "ID of the backup plan."
  value       = aws_backup_plan.this.id
}

output "plan_arn" {
  description = "ARN of the backup plan."
  value       = aws_backup_plan.this.arn
}

output "vault_arns" {
  description = "ARNs of the three vaults, keyed by role."
  value = {
    primary       = aws_backup_vault.primary.arn
    replica       = aws_backup_vault.replica.arn
    vault_account = aws_backup_vault.vault_account.arn
  }
}

output "kms_key_arns" {
  description = "ARNs of the customer managed keys backing each vault."
  value = {
    primary       = aws_kms_key.primary.arn
    replica       = aws_kms_key.replica.arn
    vault_account = aws_kms_key.vault_account.arn
  }
}

output "backup_role_arn" {
  description = "ARN of the IAM role AWS Backup assumes to run jobs."
  value       = aws_iam_role.backup.arn
}

output "selection_tags" {
  description = "Tags a resource must carry to be included. All of them are required, not any."
  value       = local.effective_selection_tags
}

output "vault_lock" {
  description = "Effective vault lock configuration, for audit evidence."
  value = {
    enabled             = var.vault_lock.enabled
    mode                = var.vault_lock.mode
    min_retention_days  = var.vault_lock.min_retention_days
    max_retention_days  = var.vault_lock.max_retention_days
    changeable_for_days = local.changeable_for_days
    reversible          = var.vault_lock.mode == "governance"
  }
}

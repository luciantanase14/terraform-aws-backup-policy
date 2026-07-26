resource "aws_backup_vault" "primary" {
  provider = aws.primary

  name        = "${var.name}-primary"
  kms_key_arn = aws_kms_key.primary.arn
  tags        = var.tags
}

resource "aws_backup_vault" "replica" {
  provider = aws.replica

  name        = "${var.name}-replica"
  kms_key_arn = aws_kms_key.replica.arn
  tags        = var.tags
}

resource "aws_backup_vault" "vault_account" {
  provider = aws.vault_account

  name        = "${var.name}-vault-account"
  kms_key_arn = aws_kms_key.vault_account.arn
  tags        = var.tags
}

data "aws_iam_policy_document" "vault_account_access" {
  statement {
    sid       = "AllowSourceAccountToCopyIn"
    effect    = "Allow"
    actions   = ["backup:CopyIntoBackupVault"]
    resources = [aws_backup_vault.vault_account.arn]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.source_account_id}:root"]
    }
  }
}

resource "aws_backup_vault_policy" "vault_account" {
  provider = aws.vault_account

  backup_vault_name = aws_backup_vault.vault_account.name
  policy            = data.aws_iam_policy_document.vault_account_access.json
}

# Passing changeable_for_days is what selects compliance mode. Governance mode
# requires leaving it null.
locals {
  compliance_mode     = var.vault_lock.mode == "compliance"
  changeable_for_days = local.compliance_mode ? var.vault_lock.changeable_for_days : null
}

resource "aws_backup_vault_lock_configuration" "primary" {
  provider = aws.primary
  count    = var.vault_lock.enabled ? 1 : 0

  backup_vault_name   = aws_backup_vault.primary.name
  min_retention_days  = var.vault_lock.min_retention_days
  max_retention_days  = var.vault_lock.max_retention_days
  changeable_for_days = local.changeable_for_days
}

resource "aws_backup_vault_lock_configuration" "replica" {
  provider = aws.replica
  count    = var.vault_lock.enabled ? 1 : 0

  backup_vault_name   = aws_backup_vault.replica.name
  min_retention_days  = var.vault_lock.min_retention_days
  max_retention_days  = var.vault_lock.max_retention_days
  changeable_for_days = local.changeable_for_days
}

resource "aws_backup_vault_lock_configuration" "vault_account" {
  provider = aws.vault_account
  count    = var.vault_lock.enabled ? 1 : 0

  backup_vault_name   = aws_backup_vault.vault_account.name
  min_retention_days  = var.vault_lock.min_retention_days
  max_retention_days  = var.vault_lock.max_retention_days
  changeable_for_days = local.changeable_for_days
}

resource "aws_backup_region_settings" "primary" {
  provider = aws.primary
  count    = var.manage_region_settings ? 1 : 0

  resource_type_opt_in_preference = var.opt_in_resource_types
}

resource "aws_backup_region_settings" "replica" {
  provider = aws.replica
  count    = var.manage_region_settings ? 1 : 0

  resource_type_opt_in_preference = var.opt_in_resource_types
}

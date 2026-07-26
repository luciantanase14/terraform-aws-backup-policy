data "aws_iam_policy_document" "vault_key" {
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.source_account_id}:root"]
    }
  }

  statement {
    sid    = "AllowBackupService"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:CreateGrant",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "vault_account_key" {
  source_policy_documents = [data.aws_iam_policy_document.vault_key.json]

  statement {
    sid       = "VaultAccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.vault_account_id}:root"]
    }
  }

  statement {
    sid    = "AllowSourceAccountToCopyIn"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:CreateGrant",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.source_account_id}:root"]
    }
  }
}

resource "aws_kms_key" "primary" {
  provider = aws.primary

  description             = "Encrypts recovery points in the ${var.name} primary vault"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_key.json
  tags                    = var.tags
}

resource "aws_kms_alias" "primary" {
  provider = aws.primary

  name          = "alias/${var.name}-backup-primary"
  target_key_id = aws_kms_key.primary.key_id
}

resource "aws_kms_key" "replica" {
  provider = aws.replica

  description             = "Encrypts recovery points in the ${var.name} cross-region vault"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_key.json
  tags                    = var.tags
}

resource "aws_kms_alias" "replica" {
  provider = aws.replica

  name          = "alias/${var.name}-backup-replica"
  target_key_id = aws_kms_key.replica.key_id
}

resource "aws_kms_key" "vault_account" {
  provider = aws.vault_account

  description             = "Encrypts recovery points copied into the ${var.name} backup account vault"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.vault_account_key.json
  tags                    = var.tags
}

resource "aws_kms_alias" "vault_account" {
  provider = aws.vault_account

  name          = "alias/${var.name}-backup-vault-account"
  target_key_id = aws_kms_key.vault_account.key_id
}

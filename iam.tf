data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  provider = aws.primary

  name               = "${var.name}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  provider = aws.primary

  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  provider = aws.primary

  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# The managed policies above do not cover S3; a tagged bucket is skipped without these.
resource "aws_iam_role_policy_attachment" "s3_backup" {
  provider = aws.primary
  count    = lookup(var.opt_in_resource_types, "S3", false) ? 1 : 0

  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Backup"
}

resource "aws_iam_role_policy_attachment" "s3_restore" {
  provider = aws.primary
  count    = lookup(var.opt_in_resource_types, "S3", false) ? 1 : 0

  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Restore"
}

data "aws_iam_policy_document" "copy" {
  statement {
    sid    = "CopyToDestinationVaults"
    effect = "Allow"
    actions = [
      "backup:CopyIntoBackupVault",
      "backup:DescribeBackupVault",
    ]
    resources = [
      aws_backup_vault.replica.arn,
      aws_backup_vault.vault_account.arn,
    ]
  }
}

resource "aws_iam_role_policy" "copy" {
  provider = aws.primary

  name   = "${var.name}-copy"
  role   = aws_iam_role.backup.id
  policy = data.aws_iam_policy_document.copy.json
}

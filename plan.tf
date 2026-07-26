resource "aws_backup_plan" "this" {
  provider = aws.primary

  name = var.name
  tags = var.tags

  dynamic "rule" {
    for_each = { for r in var.rules : r.name => r }

    content {
      rule_name                = rule.value.name
      target_vault_name        = aws_backup_vault.primary.name
      schedule                 = rule.value.schedule
      start_window             = rule.value.start_window_minutes
      completion_window        = rule.value.completion_window_minutes
      enable_continuous_backup = rule.value.enable_continuous_backup

      lifecycle {
        cold_storage_after = rule.value.cold_storage_after
        delete_after       = rule.value.delete_after
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_to_replica == null ? [] : [rule.value.copy_to_replica]

        content {
          destination_vault_arn = aws_backup_vault.replica.arn

          lifecycle {
            cold_storage_after = copy_action.value.cold_storage_after
            delete_after       = copy_action.value.delete_after
          }
        }
      }

      dynamic "copy_action" {
        for_each = rule.value.copy_to_vault_account == null ? [] : [rule.value.copy_to_vault_account]

        content {
          destination_vault_arn = aws_backup_vault.vault_account.arn

          lifecycle {
            cold_storage_after = copy_action.value.cold_storage_after
            delete_after       = copy_action.value.delete_after
          }
        }
      }
    }
  }

  depends_on = [
    aws_backup_vault_policy.vault_account,
    aws_iam_role_policy.copy,
  ]
}

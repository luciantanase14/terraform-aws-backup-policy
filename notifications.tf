# A plan with no failure alerting looks healthy while jobs have been failing for weeks.
resource "aws_backup_vault_notifications" "primary" {
  provider = aws.primary
  count    = var.notification_topic_arn == null ? 0 : 1

  backup_vault_name   = aws_backup_vault.primary.name
  sns_topic_arn       = var.notification_topic_arn
  backup_vault_events = var.notification_events
}

resource "aws_backup_vault_notifications" "replica" {
  provider = aws.replica
  count    = var.replica_notification_topic_arn == null ? 0 : 1

  backup_vault_name   = aws_backup_vault.replica.name
  sns_topic_arn       = var.replica_notification_topic_arn
  backup_vault_events = var.notification_events
}

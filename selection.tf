# AWS Backup ANDs selection_tag blocks: a resource must carry all of them.
locals {
  effective_selection_tags = merge(
    var.selection_tags,
    var.owner_tag_value == null ? {} : { Owner = var.owner_tag_value },
  )
}

resource "aws_backup_selection" "this" {
  provider = aws.primary

  name         = "${var.name}-tagged"
  plan_id      = aws_backup_plan.this.id
  iam_role_arn = aws_iam_role.backup.arn

  dynamic "selection_tag" {
    for_each = local.effective_selection_tags

    content {
      type  = "STRINGEQUALS"
      key   = selection_tag.key
      value = selection_tag.value
    }
  }
}

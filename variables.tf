variable "name" {
  description = "Base name for the vaults, plan, KMS aliases and IAM role."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,40}$", var.name))
    error_message = "Name must be 1-40 characters of letters, digits, hyphen or underscore."
  }
}

variable "source_account_id" {
  description = "Account owning the workloads and running the backup jobs."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.source_account_id))
    error_message = "source_account_id must be a 12 digit AWS account ID."
  }
}

variable "vault_account_id" {
  description = "Dedicated backup account receiving the cross-account copies."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.vault_account_id))
    error_message = "vault_account_id must be a 12 digit AWS account ID."
  }
}

variable "selection_tags" {
  description = "Tags a resource must all carry to be selected. Multiple tags are ANDed."
  type        = map(string)
  default = {
    ToBackup = "true"
  }

  validation {
    condition     = length(var.selection_tags) > 0
    error_message = "At least one selection tag is required. An empty map selects nothing."
  }
}

variable "owner_tag_value" {
  description = "Value required on the Owner tag. Null selects on the other tags alone."
  type        = string
  default     = null
}

variable "rules" {
  description = <<-EOT
    Backup rules. One schedule each, with its own retention and copy behaviour.
    Times are UTC, windows are in minutes, retention is in days. Set
    copy_to_replica or copy_to_vault_account to null to skip that copy.
  EOT

  type = list(object({
    name                      = string
    schedule                  = string
    enable_continuous_backup  = optional(bool, false)
    start_window_minutes      = optional(number, 60)
    completion_window_minutes = optional(number, 180)
    cold_storage_after        = optional(number)
    delete_after              = number

    copy_to_replica = optional(object({
      cold_storage_after = optional(number)
      delete_after       = number
    }))

    copy_to_vault_account = optional(object({
      cold_storage_after = optional(number)
      delete_after       = number
    }))
  }))

  # cold storage floor is 90 days. || is not short circuited here, hence the arithmetic
  validation {
    condition = alltrue([
      for r in var.rules :
      coalesce(r.cold_storage_after, -90) + 90 <= r.delete_after
    ])
    error_message = "delete_after must be at least cold_storage_after + 90 on every rule."
  }

  validation {
    condition = alltrue([
      for r in var.rules :
      coalesce(try(r.copy_to_replica.cold_storage_after, null), -90) + 90 <= try(r.copy_to_replica.delete_after, 0)
    ])
    error_message = "Cross-region copies follow the same rule: delete_after must be at least cold_storage_after + 90."
  }

  validation {
    condition = alltrue([
      for r in var.rules :
      coalesce(try(r.copy_to_vault_account.cold_storage_after, null), -90) + 90 <= try(r.copy_to_vault_account.delete_after, 0)
    ])
    error_message = "Cross-account copies follow the same rule: delete_after must be at least cold_storage_after + 90."
  }

  validation {
    condition     = length(var.rules) == length(distinct([for r in var.rules : r.name]))
    error_message = "Rule names must be unique within a plan."
  }
}

variable "vault_lock" {
  description = <<-EOT
    WORM protection on all three vaults.

    governance  removable by a principal holding
                backup:DeleteBackupVaultLockConfiguration
    compliance  irreversible. Once changeable_for_days elapses the lock cannot
                be removed by anyone including AWS, retention cannot be
                shortened, and the vault cannot be deleted while it holds
                recovery points. Terraform destroy will fail permanently.
  EOT

  type = object({
    enabled             = optional(bool, true)
    mode                = optional(string, "governance")
    min_retention_days  = optional(number, 7)
    max_retention_days  = optional(number, 3650)
    changeable_for_days = optional(number, 3)
  })
  default = {}

  validation {
    condition     = contains(["governance", "compliance"], var.vault_lock.mode)
    error_message = "vault_lock.mode must be governance or compliance."
  }

  validation {
    condition     = var.vault_lock.mode != "compliance" || var.vault_lock.changeable_for_days >= 3
    error_message = "Compliance mode requires a grace period of at least 3 days."
  }

  validation {
    condition     = var.vault_lock.min_retention_days <= var.vault_lock.max_retention_days
    error_message = "vault_lock.min_retention_days cannot exceed max_retention_days."
  }
}

variable "opt_in_resource_types" {
  description = <<-EOT
    Resource types AWS Backup may protect. Several are opt-out by default and a
    tag selection skips them silently, so the plan reports success while
    protecting nothing.
  EOT
  type        = map(bool)
  default = {
    "Aurora"          = true
    "DynamoDB"        = true
    "EBS"             = true
    "EC2"             = true
    "EFS"             = true
    "FSx"             = true
    "RDS"             = true
    "S3"              = true
    "Storage Gateway" = true
    "VirtualMachine"  = true
  }
}

variable "manage_region_settings" {
  description = <<-EOT
    Whether this configuration owns the account-level opt-in settings. They are
    per account and per region, so only one configuration in the account should
    set this true.
  EOT
  type        = bool
  default     = false
}

variable "kms_deletion_window_days" {
  description = "Waiting period before a scheduled KMS key deletion takes effect."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "notification_topic_arn" {
  description = "SNS topic in the primary region for vault events. Null disables notifications."
  type        = string
  default     = null
}

variable "replica_notification_topic_arn" {
  description = "SNS topic in the replica region. Topics are regional, so this cannot reuse the primary one."
  type        = string
  default     = null
}

variable "notification_events" {
  description = "Vault events published to the topics. Defaults to the failure and expiry events."
  type        = list(string)
  default = [
    "BACKUP_JOB_FAILED",
    "COPY_JOB_FAILED",
    "RESTORE_JOB_FAILED",
    "RECOVERY_POINT_MODIFIED",
  ]
}

variable "tags" {
  description = "Tags applied to every resource this module creates."
  type        = map(string)
  default     = {}
}

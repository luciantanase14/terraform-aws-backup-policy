terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

provider "aws" {
  alias  = "vault_account"
  region = var.primary_region

  assume_role {
    role_arn = var.vault_account_role_arn
  }
}

module "backup" {
  source = "../../"

  providers = {
    aws.primary       = aws.primary
    aws.replica       = aws.replica
    aws.vault_account = aws.vault_account
  }

  name              = "prod-platform"
  source_account_id = var.source_account_id
  vault_account_id  = var.vault_account_id

  selection_tags  = { ToBackup = "true" }
  owner_tag_value = var.owner_tag_value

  rules = [
    {
      name         = "daily"
      schedule     = "cron(0 2 * * ? *)"
      delete_after = 35

      copy_to_replica       = { delete_after = 35 }
      copy_to_vault_account = { delete_after = 90 }
    },
    {
      name               = "monthly-archive"
      schedule           = "cron(0 3 1 * ? *)"
      cold_storage_after = 30
      delete_after       = 2555

      copy_to_vault_account = {
        cold_storage_after = 30
        delete_after       = 2555
      }
    },
  ]

  vault_lock = {
    enabled            = true
    mode               = "governance"
    min_retention_days = 7
    max_retention_days = 3650
  }

  manage_region_settings = true

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}

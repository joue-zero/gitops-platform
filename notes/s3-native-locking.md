# Migrating off DynamoDB state locking

Terraform historically needed a DynamoDB table for state locking because S3 lacked
atomic writes. AWS added S3 Conditional Writes, and Terraform 1.10+ (stable in 1.11+)
uses that for native S3 locking via a `.tflock` companion file, making the
`dynamodb_table` backend option deprecated.

## Backend config

```hcl
terraform {
  backend "s3" {
    bucket       = "gitops-platform-tfstate-921876749389"
    key          = "dev/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true

    use_lockfile = true   # native S3 locking, replaces dynamodb_table
  }
}
```

## Migration notes

- Bucket versioning must stay enabled — native locking prevents race conditions,
  it doesn't replace backups for accidental deletions.
- IAM policy needs `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the
  `*.tflock` path alongside the state object.
- To migrate safely: add `use_lockfile = true` alongside the existing
  `dynamodb_table` entry, run `terraform init -reconfigure`, verify `terraform plan`
  works, then remove `dynamodb_table` and delete the old DynamoDB lock table.

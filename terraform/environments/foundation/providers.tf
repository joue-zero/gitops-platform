terraform {
  required_version = ">=1.15.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.45.0"
    }
  }

  backend "s3" {
    bucket       = "gitops-platform-tfstate-921876749389"
    key          = "foundation/terraform.tfstate" # separate state — never destroyed with dev
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
    # No hardcoded profile — CI authenticates via OIDC-assumed
    # credentials in the ambient environment, not a named profile.
    # Locally, set AWS_PROFILE=sofa in your shell instead.
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "foundation"
      ManagedBy   = "terraform"
      Owner       = "joe"
    }
  }
}

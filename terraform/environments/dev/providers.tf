terraform {
  required_version = ">=1.15.3"   # pin Terraform itself too

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.45.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "sofa" 

  # Tags applied to EVERY resource automatically
  default_tags {
    tags = {
      Project     = "gitops-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "joe"
    }
  }
}
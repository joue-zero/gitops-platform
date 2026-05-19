terraform {
  required_version = ">=1.15.3" # pin Terraform itself too

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.45.0"
    }
  }

  backend "s3" {
    bucket       = "gitops-platform-tfstate-921876749389" # your bucket
    key          = "dev/terraform.tfstate"                # path inside bucket
    region       = "eu-central-1"
    encrypt      = true
    profile      = "sofa"
    use_lockfile = true
  }

}

provider "aws" {
  region  = var.aws_region
  profile = "sofa"

  # Tags applied to EVERY resource automatically
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "joe"
    }
  }
}
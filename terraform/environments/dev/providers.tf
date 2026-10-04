terraform {
  required_version = ">=1.15.3" # pin Terraform itself too

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.45.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "gitops-platform-tfstate-921876749389" # your bucket
    key          = "dev/terraform.tfstate"                # path inside bucket
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

# Short-lived token from the AWS CLI (AWS_PROFILE locally, OIDC credentials in CI); no kubeconfig stored.
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}

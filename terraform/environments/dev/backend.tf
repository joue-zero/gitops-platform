# remote state config providers.tf # aws provider version pinning

terraform {
  backend "s3" {
    bucket         = "gitops-platform-tfstate-921876749389"  # your bucket
    key            = "dev/terraform.tfstate"              # path inside bucket
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "gitops-platform-tf-lock"
    profile        = "sofa"
  }
}
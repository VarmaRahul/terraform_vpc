provider "aws" {
  region = local.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.42.0"
    }
  }
}

# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-vrahul-mumbai"
#     key            = "terraform.tfstate"
#     region         = "ap-south-1"
#     dynamodb_table = "state-table"
#     encrypt        = true
#   }
# }
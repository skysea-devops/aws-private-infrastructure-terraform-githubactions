terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    # ilk init sırasında -backend-config ile dolduracağız
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


# main.tf — Phase 3


terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "<your-tf-state-bucket>"
    key            = "phase3/frontend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<your-lock-table>"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}


# Remote state — pull Phase 2 outputs


data "terraform_remote_state" "phase2" {
  backend = "s3"
  config = {
    bucket = "<your-tf-state-bucket>"
    key    = "phase2/networking.tfstate"
    region = "us-east-1"
  }
}

locals {
  p2 = data.terraform_remote_state.phase2.outputs

  tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "terraform"
  }
}

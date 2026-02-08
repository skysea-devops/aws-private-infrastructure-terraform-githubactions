variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "n8n"
}

variable "env" {
  type    = string
  default = "dev2"
}

# S3 bucket name global unique olmalı
variable "tf_state_bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-locks"
}

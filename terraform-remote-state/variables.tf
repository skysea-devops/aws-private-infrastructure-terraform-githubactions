variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "service"
}

variable "env" {
  type    = string
  default = "dev"
}

# S3 bucket name 
variable "tf_state_bucket_name" {
  type = string
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-locks"
}

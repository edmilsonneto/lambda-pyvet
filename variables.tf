variable "github_repo_owner" {
  description = "Owner of the GitHub repository"
  default = "edmilsonneto"
}

variable "github_repo_name" {
  description = "Name of the GitHub repository"
  default = "pyvet"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  default = "lambda-pyvet"
}

variable "lambda_handler_name" {
  description = "Name of the Lambda handler function"
  default = "lambda_handler"
}

variable "lambda_runtime" {
  description = "Runtime to use for the Lambda function"
  default = "python3.8"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-1"
}

variable "aws_account_id" {
  description = "Id da conta aws"
  default = "865434651024"
}
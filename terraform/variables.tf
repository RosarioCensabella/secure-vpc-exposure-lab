variable "aws_region" {
  description = "AWS Region where the lab will be deployed."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for tagging and naming resources."
  type        = string
  default     = "Secure VPC Exposure Lab"
}

variable "environment" {
  description = "Environment name for this lab."
  type        = string
  default     = "Lab"
}

variable "owner" {
  description = "Owner tag value for portfolio resources."
  type        = string
  default     = "Personal Portfolio"
}

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC."
  type        = string
  default     = "10.20.0.0/16"
}
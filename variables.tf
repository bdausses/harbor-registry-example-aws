# AWS CLI Profile
variable "aws_profile" {
  description = "The name of the AWS CLI profile to use."
  type        = string
}

# AWS Region
variable "aws_region" {
  description = "The name of the AWS region to use."
  type        = string
  default     = "us-east-1"
}

# SSH Key Name
variable "key_name" {
  type = string
}

# DNS variables
variable "domain" {
  type = string
  default = ""
}

variable "dns_record" {
  type = string
  default = ""
}

# EC2 Instance Size
variable "instance_size" {
  type = string
  default = "t3a.medium"
}

# Harbor admin password
variable "harbor_admin_password" {
  description = "Password to use for setting the admin password on your Harbor registry"
  type        = string
  default     = "Harbor12345"
}
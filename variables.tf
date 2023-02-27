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


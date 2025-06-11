variable "project_id" {
  type = string
}

variable "credentials_file" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "create_vpc" {
  description = "Set to true to create main-vpc, false to use existing"
  type        = bool
  default     = false
}

variable "create_subnet" {
  description = "Set to true to create private-subnet, false to use existing"
  type        = bool
  default     = false
}

variable "iso_url" {
  type = string
  default = ""
}

variable "iso_checksum" {
  type = string
  default = ""
}

variable "distribution" {
  type    = string
}

variable "enable_pki_install" {
  type    = bool
  default = false
}

variable "build_directory" {
  type    = string
  default = "output"
}

variable "vault_addr" {
  type    = string
  default = ""
}

variable "vault_pki_secrets_path" {
  type    = string
  default = "pki"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  description = "in megabytes"
  default = 1024
}

variable "headless" {
  type    = bool
  default = true
}

variable "https_proxy" {
  type    = string
  default = ""
}

variable "http_proxy" {
  type    = string
  default = ""
}

variable "no_proxy" {
  type    = string
  default = ""
}

locals {
  os_name = split("-", var.distribution)[0]
}

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

/* variable "mirror" { */
/*   type    = string */
/*   default = "http://cdimage.debian.org/cdimage" */
/* } */

/* variable "account" { */
/*   #default     = "" #null */
/*   default     = null */
/*   type        = string */
/*   description = "AWS account and corresponding environment into which this will be deployed" */
/*   validation { */
/*      */
/*     #condition     = (var.account == null ? true : false) || (var.account == null ? true : contains(["devops", "dev", "staging", "prod"] , var.account)) */
/*     condition     = (var.account == null ? true : contains(["devops", "dev", "staging", "prod"] , var.account)) */
/*     error_message = "Account can only be one of: devops, dev, staging, or prod." */
/*   } */
/* } */


locals {
  os_name = split("-", var.distribution)[0]
  iso_url = var.iso_url != "" ? var.iso_url : "${var.build_directory}/${var.distribution}/${var.distribution}.qcow2"
  iso_checksum = var.iso_checksum != "" ? var.iso_checksum : "file:${var.build_directory}/${var.distribution}/${var.distribution}.sha256"
}

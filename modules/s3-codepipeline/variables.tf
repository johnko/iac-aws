variable "region" {
  type = string
  description = "region"
  default = "ca-central-1"
}

variable "bucket_full_name" {
  type = string
  description = "bucket full name with account-regional suffix"
}

variable "bucket_namespace" {
  type = string
  description = "bucket namespace"
  default = "account-regional"
}

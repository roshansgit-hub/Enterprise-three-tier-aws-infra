variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "acm_certificate_arn" {
  description = "ACM cert ARN for HTTPS listener"
  type        = string
}

variable "access_logs_bucket" {
  type    = string
  default = ""
}

variable "enable_deletion_protection" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

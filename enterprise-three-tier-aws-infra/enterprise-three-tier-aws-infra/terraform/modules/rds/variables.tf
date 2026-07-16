variable "environment" {
  type = string
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "db_sg_id" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "16.3"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  type    = number
  default = 50
}

variable "max_allocated_storage" {
  type    = number
  default = 200
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "master_username" {
  type    = string
  default = "app_admin"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

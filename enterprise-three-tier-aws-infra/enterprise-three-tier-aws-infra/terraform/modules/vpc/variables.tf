variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (web tier)"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app-tier subnets"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private db-tier subnets"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to save cost (set false for HA per-AZ NAT)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_sg_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "ecr_image_uri" {
  description = "Full ECR image URI, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/app:latest"
  type        = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "alb_arn_suffix" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "db_instance_id" {
  type = string
}

variable "sns_topic_arn" {
  description = "SNS topic to notify on alarm state changes"
  type        = string
}

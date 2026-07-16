############################################
# CloudWatch dashboard + alarms for the three-tier stack
# Include this module from an environment root, e.g.:
#   module "monitoring" {
#     source          = "../../../monitoring/cloudwatch"
#     environment     = var.environment
#     alb_arn_suffix  = ...
#     asg_name        = module.ec2_asg.asg_name
#     db_instance_id  = ...
#     sns_topic_arn   = aws_sns_topic.alerts.arn
#   }
############################################

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-three-tier-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "ALB - Request Count & 5xx"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "App Tier - CPU & Instance Count"
          region  = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { stat = "Average" }],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "DB Tier - CPU, Connections, Free Storage"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id, { stat = "Average" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id, { stat = "Average" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.db_instance_id, { stat = "Average" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12, y = 6, width = 12, height = 6
        properties = {
          title   = "ALB - Target Response Time (p50/p99)"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p99" }]
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "${var.environment}-alb-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "HTTPCode_Target_5XX_Count"
  namespace            = "AWS/ApplicationELB"
  period               = 60
  statistic            = "Sum"
  threshold            = 10
  alarm_description    = "Triggers when target 5xx errors spike"
  dimensions           = { LoadBalancer = var.alb_arn_suffix }
  alarm_actions        = [var.sns_topic_arn]
  ok_actions           = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.environment}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name          = "CPUUtilization"
  namespace            = "AWS/EC2"
  period               = 60
  statistic            = "Average"
  threshold            = 80
  alarm_description    = "App tier CPU sustained above 80%"
  dimensions           = { AutoScalingGroupName = var.asg_name }
  alarm_actions        = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "db_cpu_high" {
  alarm_name          = "${var.environment}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 3
  metric_name          = "CPUUtilization"
  namespace            = "AWS/RDS"
  period               = 60
  statistic            = "Average"
  threshold            = 75
  alarm_description    = "DB CPU sustained above 75%"
  dimensions           = { DBInstanceIdentifier = var.db_instance_id }
  alarm_actions        = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "db_low_storage" {
  alarm_name          = "${var.environment}-db-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  metric_name          = "FreeStorageSpace"
  namespace            = "AWS/RDS"
  period               = 300
  statistic            = "Average"
  threshold            = 5368709120 # 5 GB in bytes
  alarm_description    = "DB free storage below 5GB"
  dimensions           = { DBInstanceIdentifier = var.db_instance_id }
  alarm_actions        = [var.sns_topic_arn]
}

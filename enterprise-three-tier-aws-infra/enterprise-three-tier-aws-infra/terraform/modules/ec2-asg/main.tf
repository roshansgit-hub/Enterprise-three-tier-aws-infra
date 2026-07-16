############################################
# App Tier - Launch Template + Auto Scaling Group
# Runs the containerized app (pulled from ECR) behind the ALB
############################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "app_instance" {
  name = "${var.environment}-app-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.app_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "cloudwatch_agent" {
  name = "${var.environment}-cw-agent-policy"
  role = aws_iam_role.app_instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:PutMetricData",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "ssm:GetParameter"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.environment}-app-instance-profile"
  role = aws_iam_role.app_instance.name
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [var.app_sg_id]

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type            = "gp3"
      encrypted              = true
      delete_on_termination  = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    ecr_image_uri = var.ecr_image_uri
    app_port      = var.app_port
    aws_region    = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.environment}-app-instance" })
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.environment}-app-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = var.private_app_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 60
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.environment}-app-instance" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

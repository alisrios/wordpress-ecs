# Auto Scaling Group para ECS
resource "aws_autoscaling_group" "this" {
  name                      = var.asg.name
  vpc_zone_identifier       = aws_subnet.public[*].id
  min_size                  = var.asg.min_size
  desired_capacity          = var.asg.desired_capacity
  max_size                  = var.asg.max_size
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "${var.ecs_cluster.name}-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Lifecycle Hook para dreno de instâncias ECS
resource "aws_autoscaling_lifecycle_hook" "ecs_terminate_hook" {
  name                   = "ecs-managed-draining-termination-hook"
  autoscaling_group_name = aws_autoscaling_group.this.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 60
  default_result         = "CONTINUE"
}
# Application Load Balancer para ECS
resource "aws_lb" "this" {
  name               = var.alb.name
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]

  tags = merge(
    var.tags,
    {
      Name = var.alb.name
    }
  )
}

# Target Group para o ALB
resource "aws_lb_target_group" "this" {
  name                 = var.alb.target_group.name
  vpc_id               = aws_vpc.this.id
  protocol             = var.alb.target_group.protocol
  port                 = var.alb.target_group.port
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.alb.health_check.path
    matcher             = "200,301,302"
    interval            = var.alb.health_check.interval
    timeout             = var.alb.health_check.timeout
    healthy_threshold   = var.alb.health_check.healthy_threshold
    unhealthy_threshold = var.alb.health_check.unhealthy_threshold
  }

  tags = merge(
    var.tags,
    {
      Name = var.alb.target_group.name
    }
  )
}

# Listener HTTP do ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.id
  port              = var.alb.listener.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

# Listener HTTPS do ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.id
  port              = var.alb.listener.https_port
  protocol          = "HTTPS"
  ssl_policy        = var.alb.listener.ssl_policy
  certificate_arn   = data.aws_acm_certificate.certificado.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }
}

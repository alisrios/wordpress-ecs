# Serviço ECS principal, gerencia containers e integra com ALB
resource "aws_ecs_service" "this" {
  name            = var.ecs_service.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.ecs_service.desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.ecs_task.container_name
    container_port   = var.ecs_task.container_port
  }

  depends_on = [
    aws_lb_listener.https
  ]

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    var.tags,
    {
      Name = var.ecs_service.name
    }
  )
}

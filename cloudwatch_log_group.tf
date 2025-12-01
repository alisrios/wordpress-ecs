# Grupo de logs do CloudWatch para ECS
resource "aws_cloudwatch_log_group" "this" {
  name              = var.ecs_task.log_group
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = var.ecs_task.log_group
    }
  )
}

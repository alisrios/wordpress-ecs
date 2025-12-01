# Cluster ECS principal do projeto
resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster.name

  tags = merge(
    var.tags,
    {
      Name = var.ecs_cluster.name
    }
  )
}
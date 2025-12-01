# Task Definition ECS para WordPress
resource "aws_ecs_task_definition" "this" {
  family             = var.ecs_task.family
  network_mode       = "bridge"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  requires_compatibilities = ["EC2"]

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  # Volume EFS
  volume {
    name = var.efs.volume_name

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.this.id
      transit_encryption = var.efs.transit_encryption
      authorization_config {
        iam = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name              = var.ecs_task.container_name
      image             = var.ecs_task.image
      essential         = true
      cpu               = var.ecs_task.cpu
      memoryReservation = var.ecs_task.memory_reservation

      portMappings = [
        {
          containerPort = var.ecs_task.container_port
          hostPort      = 0
          name          = "porta_${var.ecs_task.container_port}"
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = aws_db_instance.this.address
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.rds.username
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          value = var.rds.password
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.rds.database_name
        }
      ]

      mountPoints = [
        {
          sourceVolume  = var.efs.volume_name
          containerPath = var.efs.container_path
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.ecs_task.log_group
          "awslogs-region"        = var.auth.region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
          "mode"                  = "non-blocking"
          "max-buffer-size"       = "25m"
        }
      }

      systemControls = []
      ulimits        = []
      volumesFrom    = []
    }
  ])

  tags = merge(
    var.tags,
    {
      Name = var.ecs_task.family
    }
  )
}

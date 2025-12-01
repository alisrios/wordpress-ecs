# Busca a AMI otimizada para ECS via SSM Parameter Store
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

# Launch Template para instâncias EC2 do ECS
resource "aws_launch_template" "this" {
  name                   = var.ecs_cluster.name
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t4g.small"
  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_node.arn
  }

  monitoring {
    enabled = false
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config;
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.ecs_cluster.name}-instance"
      }
    )
  }
}

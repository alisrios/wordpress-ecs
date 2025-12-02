resource "aws_security_group" "efs" {
  name        = var.security_groups.efs.name
  description = var.security_groups.efs.description
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = var.security_groups.efs.ingress.description
    from_port       = var.security_groups.efs.ingress.from_port
    to_port         = var.security_groups.efs.ingress.to_port
    protocol        = var.security_groups.efs.ingress.protocol
    cidr_blocks     = []
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.security_groups.efs.name
    }
  )
}

resource "aws_security_group" "ec2" {
  name        = var.security_groups.ec2.name
  description = var.security_groups.ec2.description
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = var.security_groups.ec2.ingress.description
    from_port       = var.security_groups.ec2.ingress.from_port
    to_port         = var.security_groups.ec2.ingress.to_port
    protocol        = var.security_groups.ec2.ingress.protocol
    cidr_blocks     = []
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.security_groups.ec2.name
    }
  )
}

resource "aws_security_group" "alb" {
  name        = var.security_groups.alb.name
  description = var.security_groups.alb.description
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = var.security_groups.alb.ingress_https.description
    from_port       = var.security_groups.alb.ingress_https.from_port
    to_port         = var.security_groups.alb.ingress_https.to_port
    protocol        = var.security_groups.alb.ingress_https.protocol
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.security_groups.alb.name
    }
  )
}

resource "aws_security_group" "db" {
  name        = var.security_groups.db.name
  description = var.security_groups.db.description
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = var.security_groups.db.ingress.description
    from_port       = var.security_groups.db.ingress.from_port
    to_port         = var.security_groups.db.ingress.to_port
    protocol        = var.security_groups.db.ingress.protocol
    cidr_blocks     = []
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = var.security_groups.db.name
    }
  )
}

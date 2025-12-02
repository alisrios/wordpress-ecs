variable "tags" {
  type = map(string)
  default = {
    Environment = "production"
    Project     = "wordpress-ecs-tf"
  }
}

variable "auth" {
  type = object({
    assume_role_arn = string
    region          = string
  })
  default = {
    assume_role_arn = "arn:aws:iam::148761658767:role/TerraformAssumeRole"
    region          = "us-east-1"
  }
}

variable "vpc" {
  type = object({
    name                     = string
    cidr_block               = string
    instance_tenancy         = string
    enable_dns_support       = bool
    enable_dns_hostnames     = bool
    internet_gateway_name    = string
    public_route_table_name  = string
    private_route_table_name = string
    public_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    }))
    private_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    }))
  })
  default = {
    name                     = "vpc-wordpress-ecs"
    cidr_block               = "10.0.0.0/16"
    instance_tenancy         = "default"
    enable_dns_support       = true
    enable_dns_hostnames     = true
    internet_gateway_name    = "igw-wordpress-ecs"
    public_route_table_name  = "rtb-public-wordpress-ecs"
    private_route_table_name = "rtb-private-wordpress-ecs"
    public_subnets = [
      {
        name                    = "subnet-public-us-east-1a"
        cidr_block              = "10.0.0.0/20"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = true
      },
      {
        name                    = "subnet-public-us-east-1b"
        cidr_block              = "10.0.16.0/20"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = true
      }
    ]
    private_subnets = [
      {
        name                    = "subnet-private-us-east-1a"
        cidr_block              = "10.0.128.0/20"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = false
      },
      {
        name                    = "subnet-private-us-east-1b"
        cidr_block              = "10.0.144.0/20"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = false
      }
    ]
  }
}

variable "security_groups" {
  type = object({
    alb = object({
      name        = string
      description = string
      ingress_https = object({
        description = string
        from_port   = number
        to_port     = number
        protocol    = string
      })
    })
    ec2 = object({
      name        = string
      description = string
      ingress = object({
        description = string
        from_port   = number
        to_port     = number
        protocol    = string
      })
    })
    db = object({
      name        = string
      description = string
      ingress = object({
        description = string
        from_port   = number
        to_port     = number
        protocol    = string
      })
    })
    efs = object({
      name        = string
      description = string
      ingress = object({
        description = string
        from_port   = number
        to_port     = number
        protocol    = string
      })
    })
  })
  default = {
    alb = {
      name        = "alb-wordpress-tf"
      description = "Security group for Application Load Balancer"
      ingress_https = {
        description = "HTTPS from CloudFront"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
      }
    }
    ec2 = {
      name        = "ec2-wordpress-tf"
      description = "Security group for ECS instances"
      ingress = {
        description = "All traffic from ALB"
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
      }
    }
    db = {
      name        = "db-wordpress-tf"
      description = "Security group for RDS database"
      ingress = {
        description = "MySQL from ECS instances"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
      }
    }
    efs = {
      name        = "efs-wordpress-tf"
      description = "Security group for EFS"
      ingress = {
        description = "NFS from ECS instances"
        from_port   = 2049
        to_port     = 2049
        protocol    = "tcp"
      }
    }
  }
}

variable "alb" {
  type = object({
    name = string
    listener = object({
      https_port = number
      ssl_policy = string
    })
    target_group = object({
      name     = string
      protocol = string
      port     = number
    })
    health_check = object({
      path                = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  })
  default = {
    name = "alb-wordpress-tf"
    listener = {
      https_port = 443
      ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    }
    target_group = {
      name     = "tg-wordpress-tf"
      protocol = "HTTP"
      port     = 80
    }
    health_check = {
      path                = "/"
      interval            = 10
      timeout             = 5
      healthy_threshold   = 2
      unhealthy_threshold = 3
    }
  }
}

variable "ecs_cluster" {
  type = object({
    name = string
  })
  default = {
    name = "cluster-wordpress-ecs-tf"
  }
}

variable "asg" {
  type = object({
    name             = string
    min_size         = number
    desired_capacity = number
    max_size         = number
  })
  default = {
    name             = "asg-wordpress-ecs-tf"
    min_size         = 2
    desired_capacity = 2
    max_size         = 2
  }
}

variable "rds" {
  type = object({
    identifier           = string
    allocated_storage    = number
    storage_type         = string
    engine               = string
    engine_version       = string
    instance_class       = string
    username             = string
    password             = string
    database_name        = string
    parameter_group_name = string
    multi_az             = bool
    storage_encrypted    = bool
    subnet_group = object({
      name = string
    })
  })
  default = {
    identifier           = "db-wordpress-tf"
    allocated_storage    = 20
    storage_type         = "gp2"
    engine               = "mysql"
    engine_version       = "8.0"
    instance_class       = "db.t4g.micro"
    username             = "admin"
    password             = "wordpress"
    database_name        = "wordpress"
    parameter_group_name = "default.mysql8.0"
    multi_az             = false
    storage_encrypted    = true
    subnet_group = {
      name = "dbsubnet-wordpress-ecs"
    }
  }
}

variable "cloudfront" {
  type = object({
    aliases     = list(string)
    root_object = string
    price_class = string
  })
  default = {
    aliases     = ["wordpress-tf.alisriosti.com.br"]
    root_object = "index.html"
    price_class = "PriceClass_All"
  }
}

variable "ecs_service" {
  type = object({
    name          = string
    desired_count = number
  })
  default = {
    name          = "service-wordpress-tf"
    desired_count = 2
  }
}

variable "ecs_task" {
  type = object({
    family             = string
    container_name     = string
    container_port     = number
    cpu                = number
    memory_reservation = number
    image              = string
    log_group          = string
  })
  default = {
    family             = "task-def-wordpress-tf"
    container_name     = "wordpress"
    container_port     = 80
    cpu                = 1024
    memory_reservation = 410
    image              = "wordpress:latest"
    log_group          = "/ecs/task-def-wordpress-tf"
  }
}

variable "efs" {
  type = object({
    volume_name        = string
    container_path     = string
    transit_encryption = string
  })
  default = {
    volume_name        = "efs-wordpress"
    container_path     = "/var/www/html"
    transit_encryption = "ENABLED"
  }
}

variable "ecr" {
  type = object({
    repository_name = string
  })
  default = {
    repository_name = "wordpress-ecs"
  }
}

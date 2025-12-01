# EFS File System
resource "aws_efs_file_system" "this" {
  creation_token = "wordpress-efs"

  # Configurações para tornar o EFS regional
  availability_zone_name = null

  # Performance configuration
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  # Lifecycle management policies
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }


  tags = {
    Name        = "wordpress-efs"
    Environment = "production"
    Scope       = "Regional"
    ManagedBy   = "Terraform"
  }
}

resource "aws_efs_backup_policy" "redis_backup_policy" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = "DISABLED"
  }
}

# EFS Mount Targets for private subnets
resource "aws_efs_mount_target" "this" {
  count = length(var.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
# AWS Systems Manager Parameter Store para dados sensíveis

# Senha do banco de dados WordPress
resource "aws_ssm_parameter" "db_password" {
  name        = "/wordpress/db/password"
  description = "WordPress database password"
  type        = "SecureString"
  value       = var.rds.password

  tags = merge(
    var.tags,
    {
      Name = "wordpress-db-password"
    }
  )
}

# Nome do banco de dados
resource "aws_ssm_parameter" "db_name" {
  name        = "/wordpress/db/name"
  description = "WordPress database name"
  type        = "String"
  value       = var.rds.database_name

  tags = merge(
    var.tags,
    {
      Name = "wordpress-db-name"
    }
  )
}

# Usuário do banco de dados
resource "aws_ssm_parameter" "db_username" {
  name        = "/wordpress/db/username"
  description = "WordPress database username"
  type        = "String"
  value       = var.rds.username

  tags = merge(
    var.tags,
    {
      Name = "wordpress-db-username"
    }
  )
}

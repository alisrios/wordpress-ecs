resource "aws_db_instance" "this" {
  identifier             = var.rds.identifier
  allocated_storage      = var.rds.allocated_storage
  storage_type           = var.rds.storage_type
  engine                 = var.rds.engine
  engine_version         = var.rds.engine_version
  instance_class         = var.rds.instance_class
  db_name                = var.rds.database_name
  username               = var.rds.username
  password               = var.rds.password
  parameter_group_name   = var.rds.parameter_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  multi_az               = var.rds.multi_az
  storage_encrypted      = var.rds.storage_encrypted
  skip_final_snapshot    = true

  tags = merge(
    var.tags,
    {
      Name = var.rds.identifier
    }
  )
}

resource "aws_db_subnet_group" "this" {
  name       = var.rds.subnet_group.name
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    var.tags,
    {
      Name = var.rds.subnet_group.name
    }
  )
}
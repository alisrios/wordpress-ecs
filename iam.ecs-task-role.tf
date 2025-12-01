# IAM Role para as tarefas ECS (aplicação)
# Permite que os containers acessem recursos AWS (ex: EFS, S3, etc)

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "ecs-wordpress-task-role-tf-"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Permissão para acessar EFS
resource "aws_iam_role_policy_attachment" "efs_read_write_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

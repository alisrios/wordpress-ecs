# IAM Role para instâncias EC2 do ECS
# Permite que as instâncias EC2 se registrem no cluster e executem containers

data "aws_iam_policy_document" "ecs_instance_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs-instance-role-tf"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role.json
}

# Políticas gerenciadas anexadas à Instance Role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile para anexar a role às instâncias EC2
resource "aws_iam_instance_profile" "ecs_node" {
  name = "ecs-instance-role-profile-tf"
  path = "/ecs/instance/"
  role = aws_iam_role.ecs_instance_role.name
}

# IAM Role for EC2 (self-hosted-runner) with ECR + EKS (Admin) access
resource "aws_iam_role" "self-hosted-runner_combined_role" {
  name = "self-hosted-runner-combined-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.roles_tags
}

# Attach ECR full access policy
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.self-hosted-runner_combined_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Attach Administrator access (or you can restrict to AmazonEKS* if needed)
resource "aws_iam_role_policy_attachment" "eks_admin_access" {
  role       = aws_iam_role.self-hosted-runner_combined_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Instance profile for EC2 to use the above role
resource "aws_iam_instance_profile" "self-hosted-runner_instance_profile" {
  name = "self-hosted-runner-combined-profile"
  role = aws_iam_role.self-hosted-runner_combined_role.name
}

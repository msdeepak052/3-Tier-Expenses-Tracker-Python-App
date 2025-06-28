# Create an ECR repository
resource "aws_ecr_repository" "example" {
  name                 = var.name_ecr
  image_tag_mutability = var.enable_immutable_tags ? "IMMUTABLE" : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = var.ecr_tags
}


output "self-hosted-runner_instance_ip" {
  description = "Public IP of self-hosted-runner instance"
  value       = aws_eip.self-hosted-runner.public_ip
}

output "nexus_instance_ip" {
  description = "Public IP of Nexus instance"
  value       = aws_eip.nexus.public_ip
}

output "sonarqube_instance_ip" {
  description = "Public IP of SonarQube instance"
  value       = aws_eip.sonarqube.public_ip
}

# output "eks_admin_instance_ip" {
#   description = "Public IP of SonarQube instance"
#   value       = aws_eip.eks_admin.public_ip
# }

output "self-hosted-runner_role_arn" {
  value = aws_iam_role.self-hosted-runner_combined_role.arn
}



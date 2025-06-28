output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.deepak-eks-cluster.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = aws_eks_cluster.deepak-eks-cluster.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.deepak-eks-cluster.certificate_authority[0].data
}

output "node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

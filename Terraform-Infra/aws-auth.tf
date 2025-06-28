resource "kubectl_manifest" "aws_auth" {
  depends_on = [
    module.eks
  ]

  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${module.eks.node_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${module.ec2.self-hosted-runner_role_arn}
      username: admin
      groups:
        - system:masters
YAML
}

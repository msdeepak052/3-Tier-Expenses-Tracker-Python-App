output "security_group_ids" {
  description = "IDs of all created security groups"
  value = {
    for name, sg in aws_security_group.dynamic_sgs :
    name => sg.id
  }
}

#   vpc_security_group_ids = [
#     module.networking.security_group_ids["sonarqube"],
#     module.networking.security_group_ids["eks-admin"]
#   ]

# VPC Configuration for CodeBuild Projects
# Using public subnets with IGW (no NAT Gateway) for zero cost

module "vpc_codebuild" {
  source = "../../modules/vpc-codebuild"

  name_prefix         = "terraform"
  vpc_cidr            = "10.69.0.0/16"
  public_subnet_cidrs = ["10.69.0.0/22", "10.69.4.0/22"]
}

# Resource references for backward compatibility
locals {
  vpc_id             = module.vpc_codebuild.vpc_id
  public_subnet_ids  = module.vpc_codebuild.public_subnet_ids
  security_group_id  = module.vpc_codebuild.security_group_id
}

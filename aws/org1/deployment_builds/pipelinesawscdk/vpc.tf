# VPC Configuration for CDK CodeBuild Projects
# Using public subnets with IGW (no NAT Gateway) for zero cost
# Separate VPC from Terraform pipelines to avoid conflicts

module "vpc_codebuild" {
  source = "../../modules/vpc-codebuild"

  name_prefix         = "cdk"
  vpc_cidr            = "10.68.0.0/16"
  public_subnet_cidrs = ["10.68.0.0/22", "10.68.4.0/22"]
}
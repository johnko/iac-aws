# VPC Configuration for CodeBuild Projects
# Using public subnets with IGW (no NAT Gateway) for zero cost

locals {
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
}

# VPC
resource "aws_vpc" "codebuild" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "codebuild-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "codebuild" {
  vpc_id = aws_vpc.codebuild.id

  tags = {
    Name = "codebuild-igw"
  }
}

# Public Subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count = length(local.public_subnet_cidrs)

  vpc_id                  = aws_vpc.codebuild.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "codebuild-public-${count.index}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.codebuild.id

  tags = {
    Name = "codebuild-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.codebuild.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for CodeBuild
resource "aws_security_group" "codebuild" {
  name        = "codebuild-sg"
  description = "Security group for CodeBuild projects"
  vpc_id      = aws_vpc.codebuild.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "codebuild-sg"
  }
}

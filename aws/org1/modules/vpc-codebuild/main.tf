# VPC Configuration for CodeBuild Projects
# Using public subnets with IGW (no NAT Gateway) for zero cost

# VPC
resource "aws_vpc" "codebuild" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-codebuild-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "codebuild" {
  vpc_id = aws_vpc.codebuild.id

  tags = {
    Name = "${var.name_prefix}-codebuild-igw"
  }
}

# Public Subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.codebuild.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-codebuild-public-${count.index}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.codebuild.id

  tags = {
    Name = "${var.name_prefix}-codebuild-public-rt"
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
  name        = "${var.name_prefix}-codebuild-sg"
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
    Name = "${var.name_prefix}-codebuild-sg"
  }
}
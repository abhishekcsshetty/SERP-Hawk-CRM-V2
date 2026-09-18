# ==============================================================================
# Module: Networking
# Resources: VPC, Internet Gateway, Public Subnet, Route Table, Association
# ==============================================================================

# 1. Custom VPC
resource "aws_vpc" "crm_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "serphawk-${var.environment}-vpc"
  })
}

# 2. Internet Gateway (IGW)
resource "aws_internet_gateway" "crm_igw" {
  vpc_id = aws_vpc.crm_vpc.id

  tags = merge(var.tags, {
    Name = "serphawk-${var.environment}-igw"
  })
}

# 3. Public Subnet
resource "aws_subnet" "crm_public_subnet" {
  vpc_id                  = aws_vpc.crm_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = merge(var.tags, {
    Name = "serphawk-${var.environment}-public-subnet"
  })
}

# 4. Route Table (RT) for Public Subnet
resource "aws_route_table" "crm_public_rt" {
  vpc_id = aws_vpc.crm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.crm_igw.id
  }

  tags = merge(var.tags, {
    Name = "serphawk-${var.environment}-public-rt"
  })
}

# 5. Route Table Association
resource "aws_route_table_association" "crm_public_rta" {
  subnet_id      = aws_subnet.crm_public_subnet.id
  route_table_id = aws_route_table.crm_public_rt.id
}

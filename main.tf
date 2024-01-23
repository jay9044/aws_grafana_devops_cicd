locals {
  azs = data.aws_availability_zones.az_zones.names
}

resource "random_id" "random_tag" {
  byte_length = 2
}

resource "aws_vpc" "tfa_vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tfansible - ${random_id.random_tag.dec}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_internet_gateway" "tfa_igw" {
  vpc_id = aws_vpc.tfa_vpc.id

  tags = {
    Name = "tfansible_igw - ${random_id.random_tag.dec}"
  }
}

resource "aws_route_table" "tfa_public_rtb" {
  vpc_id = aws_vpc.tfa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfa_igw.id
  }

  tags = {
    Name = "tfa-public-rtb"
  }
}

resource "aws_default_route_table" "tfa_private_rtb" {
  default_route_table_id = aws_vpc.tfa_vpc.default_route_table_id

  tags = {
    Name = "tfa-private-rtb"
  }
}

//using count to accommodate Dry principles
resource "aws_subnet" "tfa_public_subnet" {
  count      = length(var.public_cidrs)
  vpc_id     = aws_vpc.tfa_vpc.id
  cidr_block = var.public_cidrs[count.index]

  //Specify true to indicate that instances launched into the subnet should be assigned a public IP address.
  map_public_ip_on_launch = true

  availability_zone = local.azs[count.index]

  tags = {
    Name = "tfa_public_subnet-${count.index + 1}" //so tags start at 1 for readability
  }
}

resource "aws_subnet" "tfa_private_subnet" {
  count             = length(var.private_cidrs)
  vpc_id            = aws_vpc.tfa_vpc.id
  availability_zone = local.azs[count.index]

  tags = {
    Name = "tfa_private_subnet-${count.index + 1}"
  }
}
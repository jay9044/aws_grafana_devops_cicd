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

//default vpc route table is being used a private rtb // implicit association to private rtb
resource "aws_default_route_table" "tfa_private_rtb" {
  default_route_table_id = aws_vpc.tfa_vpc.default_route_table_id

  tags = {
    Name = "tfa-private-rtb"
  }
}

//using count to accommodate Dry principles
resource "aws_subnet" "tfa_public_subnet" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.tfa_vpc.id
  availability_zone = local.azs[count.index]

  //last bit will start with a 0 due to count index
  cidr_block = cidrsubnet(var.vpc_cidr_block, 8, count.index)

  //Specify true to indicate that instances launched into the subnet should be assigned a public IP address.
  map_public_ip_on_launch = true

  tags = {
    Name = "tfa_public_subnet-${count.index + 1}" //so tags start at 1 for readability
  }
}

resource "aws_subnet" "tfa_private_subnet" {
  count             = length(local.azs)
  vpc_id            = aws_vpc.tfa_vpc.id
  availability_zone = local.azs[count.index]

  //so pub and private subnets dont clash
  cidr_block = cidrsubnet(var.vpc_cidr_block, 8, length(local.azs) + count.index)

  tags = {
    Name = "tfa_private_subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "tfa_public_rtb_assoc" {
  count          = length(local.azs)
  route_table_id = aws_route_table.tfa_public_rtb.id
  subnet_id      = aws_subnet.tfa_public_subnet[count.index].id
}

resource "aws_security_group" "tfa_sg" {
  name        = "tfa_sg"
  description = "tfa_public_sg"
  vpc_id      = aws_vpc.tfa_vpc.id

  ingress {
    description = "All ingress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" //all protocols
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "tfa-sg"
  }
}

resource "aws_key_pair" "tfa_ssh_key" {
  key_name   = "tfa_ssh_key"
  public_key = file(var.ssh_pub_key_path)
}
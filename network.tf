resource "aws_vpc" "vpc" {
  assign_generated_ipv6_cidr_block = false
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
  tags = {
    "Name" = "${var.project_name}-${var.env}"
  }
}

resource "aws_subnet" "public_subnet_01" {
  assign_ipv6_address_on_creation = false
  availability_zone = "ap-northeast-2a"
  cidr_block = "10.1.0.0/18"
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.project_name}-${var.env}-p01"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_02" {
  assign_ipv6_address_on_creation = false
  availability_zone = "ap-northeast-2c"
  cidr_block = "10.1.64.0/18"
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.project_name}-${var.env}-p02"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private_subnet_01" {
  assign_ipv6_address_on_creation = false
  availability_zone = "ap-northeast-2a"
  cidr_block = "10.1.128.0/18"
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.project_name}-${var.env}-i01"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_subnet_02" {
  assign_ipv6_address_on_creation = false
  availability_zone = "ap-northeast-2c"
  cidr_block = "10.1.192.0/18"
  map_public_ip_on_launch = false
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.project_name}-${var.env}-i02"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.project_name}-${var.env}"
  }
}

resource "aws_eip" "eip_01" {
  public_ipv4_pool = "amazon"
  domain = "vpc"
}

resource "aws_eip" "eip_02" {
  public_ipv4_pool = "amazon"
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway_01" {
  allocation_id = aws_eip.eip_01.id
  subnet_id     = aws_subnet.public_subnet_01.id

  tags = {
    Name = "${var.project_name}-${var.env}-01"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway_02" {
  allocation_id = aws_eip.eip_02.id
  subnet_id     = aws_subnet.public_subnet_02.id

  tags = {
    Name = "${var.project_name}-${var.env}-02"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table" "private_route_table_01" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_01.id
  }
}

resource "aws_route_table" "private_route_table_02" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_02.id
  }
}

resource "aws_route_table_association" "route_table_association_p01" {
  subnet_id = aws_subnet.public_subnet_01.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "route_table_association_p02" {
  subnet_id = aws_subnet.public_subnet_02.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "route_table_association_i01" {
  subnet_id = aws_subnet.private_subnet_01.id
  route_table_id = aws_route_table.private_route_table_01.id
}

resource "aws_route_table_association" "route_table_association_i02" {
  subnet_id = aws_subnet.private_subnet_02.id
  route_table_id = aws_route_table.private_route_table_02.id
}

resource "aws_security_group" "cluster_sg" {
  name = "cluster-sg"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "${var.project_name}-${var.env}"
  }
}

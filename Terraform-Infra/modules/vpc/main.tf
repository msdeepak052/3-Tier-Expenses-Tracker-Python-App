resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "subnets" {
  for_each = {
    for subnet in var.subnets : 
      subnet.name => subnet
  }

  vpc_id            = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = can(regex("public", each.key))

  tags = {
    Name = "${var.vpc_name}-${each.key}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_eip" "nat-eip" {
    domain                    = "vpc"
}

resource "aws_nat_gateway" "deepak-nat" {
  subnet_id = element(
    [
      for subnet in aws_subnet.subnets : subnet.id
      if can(regex("public", subnet.tags["Name"]))  # Match against the Name tag
    ],
    0
  )
  # subnet_id = [for k, subnet in aws_subnet.subnets : subnet.id if can(regex("public", k))][0]
  allocation_id = aws_eip.nat-eip.id

  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }
    # To ensure proper ordering, it is recommended to add an explicit dependency
    # on the Internet Gateway for the VPC.
    depends_on = [aws_internet_gateway.gw]
}


resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.vpc_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public-rt-association" {
  for_each = {
        for subnet in var.subnets : subnet.name => subnet
            if can(regex("public", subnet.name))
        }
  subnet_id = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.public-rt.id
  
}

resource "aws_route_table" "pvt-rt" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-pvt-rt"  }
  
}

resource "aws_route" "pvt-rt-route" {
  route_table_id = aws_route_table.pvt-rt.id
  destination_cidr_block = var.pvt_destination_route_cidr
  nat_gateway_id = aws_nat_gateway.deepak-nat.id

}

resource "aws_route_table_association" "pvt-rt-saasociation" {
  for_each = {
        for subnet in var.subnets : subnet.name => subnet
            if can(regex("private", subnet.name))
        }
  subnet_id = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.pvt-rt.id
  
}


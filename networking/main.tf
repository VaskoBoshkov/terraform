# --- networking/main.tf

data "aws_availability_zones" "available" {

}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "vasko_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vasko_vpc-${random_integer.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "vasko_public_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.vasko_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "vasko_public_${count.index + 1}"
  }
}

resource "aws_route_table_association" "vasko_public_association" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.vasko_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.vasko_public_rt.id
}

resource "aws_subnet" "vasko_private_subnet" {
  count      = var.private_sn_count
  vpc_id     = aws_vpc.vasko_vpc.id
  cidr_block = var.private_cidr[count.index]
  # map_public_ip_on_launch = false
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "vasko_private_${count.index + 1}"
  }
}

resource "aws_internet_gateway" "vasko_internet_gateway" {
  vpc_id = aws_vpc.vasko_vpc.id

  tags = {
    Name = "vasko_igw"
  }
}

resource "aws_route_table" "vasko_public_rt" {
  vpc_id = aws_vpc.vasko_vpc.id

  tags = {
    Name = "vasko_public"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.vasko_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vasko_internet_gateway.id
}

resource "aws_default_route_table" "vasko_private_rt" {
  default_route_table_id = aws_vpc.vasko_vpc.default_route_table_id

  tags = {
    Name = "vasko_private"
  }
}

resource "aws_security_group" "vasko_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.vasko_vpc.id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "vasko_rds_subnetgroup" {
  name       = "vasko_rds_subnetgroup"
  count      = var.db_subnet_group == true ? 1 : 0
  subnet_ids = aws_subnet.vasko_private_subnet.*.id

  tags = {
    Name = "vasko_rds_sng"
  }
}

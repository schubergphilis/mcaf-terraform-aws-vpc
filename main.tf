locals {
  az_ids = [for zone in var.availability_zones : substr(zone, length(zone) - 1, 1)]
  zones  = length(var.availability_zones)
}

resource "aws_vpc" "default" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags                 = merge(var.tags, { "Name" = "${var.stack}-vpc" })
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags   = merge(var.tags, { "Name" = "${var.stack}-igw" })
}

resource "aws_eip" "nat" {
  count = local.zones
  vpc   = true

  tags = merge(
    var.tags, { "Name" = "${var.stack}-nat-${local.az_ids[count.index]}" }
  )

  depends_on = [aws_internet_gateway.default]
}

resource "aws_nat_gateway" "default" {
  count         = local.zones
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags, { "Name" = "${var.stack}-nat-${local.az_ids[count.index]}" }
  )
}

resource "aws_subnet" "public" {
  count                   = local.zones
  cidr_block              = cidrsubnet(var.cidr_block, var.extra_bits_per_subnet, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.default.id

  tags = merge(
    var.tags, { "Name" = "${var.stack}-public-${local.az_ids[count.index]}" }
  )
}

resource "aws_subnet" "private" {
  count                   = local.zones
  cidr_block              = cidrsubnet(var.cidr_block, var.extra_bits_per_subnet, count.index + local.zones)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.default.id

  tags = merge(
    var.tags, { "Name" = "${var.stack}-private-${local.az_ids[count.index]}" }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags   = merge(var.tags, { "Name" = "${var.stack}-public" })
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table_association" "public" {
  count          = local.zones
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = local.zones
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags, { "Name" = "${var.stack}-private-${local.az_ids[count.index]}" }
  )
}

resource "aws_route" "private" {
  count                  = local.zones
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = local.zones
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

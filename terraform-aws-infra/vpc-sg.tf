
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${var.project}-${var.env}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project}-${var.env}-igw" })
}

resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs_effective : idx => az }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = var.public_subnet_cidrs[tonumber(each.key)]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project}-${var.env}-public-${each.value}"
    Tier = "public"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project}-${var.env}-public-rt" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.env}-alb-sg"
  description = "ALB SG"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.project}-${var.env}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_443_in" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_80_in" {
  count             = var.enable_http_redirect ? 1 : 0
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet (redirect to HTTPS)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_service" {
  security_group_id            = aws_security_group.alb.id
  description                  = "To service SG on app port"
  ip_protocol                  = "tcp"
  from_port                    = var.service_app_port
  to_port                      = var.service_app_port
  referenced_security_group_id = aws_security_group.service.id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_azure_oidc" {
  security_group_id = aws_security_group.alb.id
  description       = "ALB to Azure OIDC endpoints for token verification"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "service" {
  name        = "${var.project}-${var.env}-service-sg"
  description = "service app SG (only from ALB, no SSH)"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.project}-${var.env}-service-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "service_from_alb" {
  security_group_id            = aws_security_group.service.id
  description                  = "App port from ALB only"
  ip_protocol                  = "tcp"
  from_port                    = var.service_app_port
  to_port                      = var.service_app_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "service_all_out" {
  security_group_id = aws_security_group.service.id
  description       = "service outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.env}-rds-sg"
  description = "RDS SG (only from service on 5432)"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${var.project}-${var.env}-rds-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_service" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Postgres from service SG only"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.service.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all_out" {
  security_group_id = aws_security_group.rds.id
  description       = "RDS outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

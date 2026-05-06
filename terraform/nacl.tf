resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "nacl-secure-vpc-public"
    Tier = "Public"
  }
}

resource "aws_network_acl" "private_app" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "nacl-secure-vpc-private-app"
    Tier = "Private"
    Role = "Application"
  }
}

resource "aws_network_acl_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  network_acl_id = aws_network_acl.public.id
}

resource "aws_network_acl_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  network_acl_id = aws_network_acl.private_app.id
}

resource "aws_network_acl_association" "private_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  network_acl_id = aws_network_acl.private_app.id
}

resource "aws_network_acl_rule" "public_ingress_http_from_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_ingress_ephemeral_from_private_app" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.20.10.0/23"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_egress_app_traffic_to_private_app" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.20.10.0/23"
  from_port      = 8080
  to_port        = 8080
}

resource "aws_network_acl_rule" "public_egress_ephemeral_to_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_ingress_explicit_deny_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 32766
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "public_egress_explicit_deny_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 32766
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_app_ingress_app_traffic_from_public" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.20.0.0/23"
  from_port      = 8080
  to_port        = 8080
}

resource "aws_network_acl_rule" "private_app_egress_ephemeral_to_public" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "10.20.0.0/23"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_app_ingress_explicit_deny_all" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 32766
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "private_app_egress_explicit_deny_all" {
  network_acl_id = aws_network_acl.private_app.id
  rule_number    = 32766
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
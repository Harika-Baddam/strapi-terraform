#VPC
data "aws_vpc" "default_vpc" {
  default = true
}
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}


#east-2a subnet
data "aws_subnets" "subnet_a" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-2a"]
  }
}
data "aws_subnet" "public_subnet_a" {
  id = element(data.aws_subnets.subnet_a.ids, 0)
}
#east-2b subnet
data "aws_subnets" "subnet_b" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-2b"]
  }
}
data "aws_subnet" "public_subnet_b" {
  id = element(data.aws_subnets.subnet_b.ids, 0)
}



#Security Groups
resource "aws_security_group" "public_sg" {
  name                   = "public_sg-hrk"
  description            = "SG for instances in Public Subnet."
  vpc_id                 = data.aws_vpc.default_vpc.id
  egress                 = []
  revoke_rules_on_delete = true

  tags = {
    Name = "strapi_public_security_group-hrk"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http_from_internet_to_public_sg" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow inbound HTTP from internet"
}
resource "aws_vpc_security_group_ingress_rule" "alb_to_ecs_on_1337" {
  security_group_id            = aws_security_group.public_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id
  from_port                    = 1337
  to_port                      = 1337
  ip_protocol                  = "tcp"
  description                  = "Allow ALB to ECS on port 1337"
}
resource "aws_vpc_security_group_ingress_rule" "ecs_to_postgres_5432" {
  security_group_id            = aws_security_group.public_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow ECS to connect to PostgreSQL on port 5432"
}
resource "aws_vpc_security_group_egress_rule" "to_internet_from_public_sg" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allows outbound connections to internet via NAT gateway"
}


#Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb-strapi-hrk"
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.public_subnet_a.id, data.aws_subnet.public_subnet_b.id]
  security_groups    = [aws_security_group.public_sg.id]
  internal           = false

  tags = {
    Name = "strapi_load_balancer-hrk"
  }
}
resource "aws_lb_listener" "app_lb_http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }

  tags = {
    Name = "app_lb_http_listener-hrk"
  }
}
resource "aws_lb_target_group" "strapi_tg" {
  name        = "strapi-target-group-hrk"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default_vpc.id
  target_type = "ip"

  health_check {
    path                = "/admin"
    protocol            = "HTTP"
    matcher             = "200-299"
    port                = 1337
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "strapi_target_group-hrk"
  }
}


#Database
resource "aws_db_subnet_group" "strapi_postgres_subnet_group" {
  name       = "strapi-postgres-subnet-group-hrk"
  subnet_ids = [data.aws_subnet.public_subnet_a.id, data.aws_subnet.public_subnet_b.id]

  tags = {
    Name = "strapi_postgres_subnet_group-hrk"
  }
}
resource "aws_db_parameter_group" "strapi_postgres_param_group" {
  name        = "strapi-postgres-param-group-hrk"
  family      = "postgres17"
  description = "Custom parameter group for Strapi Postgres"

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name = "strapi_postgres_param_group-hrk"
  }
}
resource "aws_db_instance" "strapi_rds_postgresql" {
  allocated_storage      = 10
  db_name                = var.database_name
  identifier             = "strapi-postgres"
  engine                 = "postgres"
  engine_version         = "17.2"
  instance_class         = "db.t3.micro"
  username               = var.database_username
  password               = var.database_password
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.strapi_postgres_subnet_group.name
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.strapi_postgres_param_group.name

  tags = {
    Name = "strapi_postgres_DB-hrk"
  }
}



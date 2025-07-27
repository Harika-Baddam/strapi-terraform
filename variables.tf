variable "availability_zones" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b"]
}

variable "database_client" {
  type    = string
  default = "postgres" #Default is "postgres"
}

variable "database_port" {
  type    = string
  default = "5432"
}

variable "database_name" {
  type    = string
  default = "strapi"
}

variable "database_username" {
  type    = string
  default = "strapi" #Enter Your DB User - Default is "strapi"
}

variable "database_password" {
  type    = string
  default = "password" #Enter Your DB Password - Default is "password"
}

locals {
  database_host = aws_db_instance.strapi_rds_postgresql.address
}

output "app_lb_endpoint" {
  value = aws_lb.app_lb.dns_name
}


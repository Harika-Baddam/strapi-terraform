output "strapi_url" {
  description = "Public URL to access Strapi"
  value       = "http://${aws_lb.strapi.dns_name}"
}

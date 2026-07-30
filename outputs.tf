output "route53_name_servers" {
  description = "Copy this 4 lines into nic.ua"
  value       = aws_route53_zone.main_zone.name_servers
}
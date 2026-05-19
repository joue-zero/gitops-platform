output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
output "app_private_ips" { value = aws_instance.app[*].private_ip }
output "alb_dns_name" { value = aws_lb.main.dns_name }

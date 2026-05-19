variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "bastion_sg_id" { type = string }
variable "app_sg_id" { type = string }
variable "alb_sg_id" { type = string }
variable "key_pair_name" { type = string }
variable "ec2_instance_profile" { type = string }
variable "acm_cert_arn" {
  type    = string
  default = ""
}

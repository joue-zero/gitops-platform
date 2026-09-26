variable "project_name" { type = string }

variable "data_subnet_ids" {
  description = "Subnet IDs (2+ AZs) for the RDS subnet group"
  type        = list(string)
}

variable "db_sg_id" {
  description = "Security group ID allowing Postgres traffic from app servers"
  type        = string
}

variable "db_name" {
  type    = string
  default = "gitopsapp"
}

variable "db_username" {
  type    = string
  default = "gitopsadmin"
}

variable "db_engine_version" {
  type    = string
  default = "16.4"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "project_id" { type = string }
variable "region"      { type = string }
variable "db_password" { type = string }

variable "allowed_cidrs" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR blocks allowed to access HAProxy"
}

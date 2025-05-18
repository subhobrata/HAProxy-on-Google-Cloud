variable "project_id" { type = string }
variable "region"      { type = string }
variable "db_password" { type = string }

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach HAProxy"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

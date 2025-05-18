variable "project_id" { type = string }
variable "region"      { type = string }
variable "db_password" { type = string }

variable "allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach HAProxy"
  default     = ["0.0.0.0/0"]
}

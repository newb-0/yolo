variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "yolomy"
}

variable "server_port" {
  description = "Server port"
  type        = number
  default     = 5002
}

variable "client_port" {
  description = "Client port"
  type        = number
  default     = 3000
}
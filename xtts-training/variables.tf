variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "g5.xlarge"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 100
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

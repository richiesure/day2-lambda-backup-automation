# variables.tf - Input variables for Lambda backup automation

# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

# Target EC2 instance ID from Day 1 to enable backup
variable "target_instance_id" {
  description = "EC2 instance ID to tag for backup (from Day 1)"
  type        = string
  default     = "i-077464828f9d99024"  # Your Day 1 instance ID
}

variable "aws_region" {
  type        = string
  description = "The region where the instance running"
  default     = "eu_north_1"
}

variable "instance_type" {
  type        = string
  description = "The type of the AWS EC2 instance"
  default     = "t3.micro"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the main vpc"
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  type        = string
  description = "The CIDR block for the public subnet a"
  default     = "10.0.1.0/24"
}

variable "private_subnet_a_cidr" {
  type        = string
  description = "The CIDR block for the private subnet a"
  default     = "10.0.2.0/24"
}

variable "public_subnet_b_cidr" {
  type        = string
  description = "The CIDR block for the public subnet b"
  default     = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  type        = string
  description = "The CIDR block for the private subnet b"
  default     = "10.0.4.0/24"
}
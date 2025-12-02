variable "aws_region" {
  description = "aws region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "environment"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "resource naming"
  type        = string
  default     = "ha-ec2-setup"
}

variable "vpc_cidr" {
  description = "cidr block for vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "number of public subnets"
  type        = number
  default     = 2
}

variable "allowed_ssh_ip" {
  description = "ip address ssh allowed to the instance"
  type        = string
  default     = "88.196.208.91"
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^(t3\\.medium|t3\\.large)", var.instance_type))
    error_message = "not allowed instance selected"
  }
}

variable "root_volume_size" {
  description = "root volume in gb"
  type        = number
  default     = 20
}

variable "ebs_volume_size" {
  description = "ebs volumes in gb"
  type        = number
  default     = 50
}

variable "ebs_volume_type" {
  description = "type of ebs vol"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.ebs_volume_type)
    error_message = "ebs volume allowed type: gp3, gp2, io1, io2."
  }
}

variable "ebs_volume_iops" {
  description = "iops for ebs volumes"
  type        = number
  default     = 3000
}

variable "ebs_volume_throughput" {
  description = "throughput for ebs vol in mb/s (gp3)"
  type        = number
  default     = 125
}

variable "enable_termination_protection" {
  description = "enable ec2 termination protection"
  type        = bool
  default     = true
}

variable "prevent_volume_destroy" {
  description = "prevent ebs volume destruction"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "sns topic arn for cloudWatch alarms"
  type        = string
  default     = ""
}

variable "ec2_secrets" {
  type        = map(string)
  description = "preconfigured ssh key pairs"
  default = {
    test1-ssh = "test1-ssh-pair"
  }
}

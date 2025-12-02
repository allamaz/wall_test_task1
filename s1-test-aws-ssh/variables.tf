variable "ssh_users" {
  type        = list(string)
  description = "ssh key pairs"
  default     = ["test1"]
}

variable "aws_region" {
  type        = string
  description = "aws region"
  default     = "eu-west-1"
}

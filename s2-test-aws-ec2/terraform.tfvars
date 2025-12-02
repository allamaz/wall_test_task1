aws_region   = "eu-west-1"
environment  = "production"
project_name = "ha-ec2-setup"

vpc_cidr     = "10.0.0.0/16"
subnet_count = 2

allowed_ssh_ip = "88.196.208.91"

instance_type    = "t3.medium"
root_volume_size = 20

ebs_volume_size       = 50
ebs_volume_type       = "gp3"
ebs_volume_iops       = 3000
ebs_volume_throughput = 125

enable_termination_protection = true
prevent_volume_destroy        = true
sns_topic_arn                 = ""

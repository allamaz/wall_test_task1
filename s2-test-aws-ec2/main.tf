data "aws_secretsmanager_secret" "test1-ssh" {
  name = var.ec2_secrets["test1-ssh"]
}
data "aws_secretsmanager_secret_version" "test1-ssh_version" {
  secret_id  = data.aws_secretsmanager_secret.test1-ssh.id
  depends_on = [data.aws_secretsmanager_secret.test1-ssh]
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  description = "sec.grp. for ec2 instance with restricted access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "ssh access from allowed ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ssh_ip}/32"]
  }

  egress {
    description = "https outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "http outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "dns outbound"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

locals {
  test1_kp = jsondecode(data.aws_secretsmanager_secret_version.test1-ssh_version.secret_string)
}

resource "aws_instance" "main" {
  ami                                  = data.aws_ami.amazon_linux_2023.id
  key_name                             = local.test1_kp.pub
  instance_type                        = var.instance_type
  subnet_id                            = aws_subnet.public[0].id
  vpc_security_group_ids               = [aws_security_group.ec2.id]
  iam_instance_profile                 = aws_iam_instance_profile.ec2_profile.name
  monitoring                           = true
  disable_api_termination              = var.enable_termination_protection
  instance_initiated_shutdown_behavior = "stop"
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = false
    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", { hostname = "${var.project_name}-instance" }))
  tags = {
    Name             = "${var.project_name}-instance"
    HighAvailability = "true"
    BackupPolicy     = "daily"
  }
  lifecycle {
    ignore_changes = [
      ami, user_data
    ]
  }
}

resource "aws_ebs_volume" "data_volume_1" {
  availability_zone = aws_instance.main.availability_zone
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true
  iops              = var.ebs_volume_type == "gp3" ? var.ebs_volume_iops : null
  throughput        = var.ebs_volume_type == "gp3" ? var.ebs_volume_throughput : null
  tags = {
    Name        = "${var.project_name}-data-volume-1"
    VolumeIndex = "1"
    Backup      = "daily"
  }
}

resource "aws_ebs_volume" "data_volume_2" {
  availability_zone = aws_instance.main.availability_zone
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true
  iops              = var.ebs_volume_type == "gp3" ? var.ebs_volume_iops : null
  throughput        = var.ebs_volume_type == "gp3" ? var.ebs_volume_throughput : null
  tags = {
    Name        = "${var.project_name}-data-volume-2"
    VolumeIndex = "2"
    Backup      = "daily"
  }
}

resource "aws_volume_attachment" "data_volume_1_attachment" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.data_volume_1.id
  instance_id  = aws_instance.main.id
  skip_destroy = var.prevent_volume_destroy
}

resource "aws_volume_attachment" "data_volume_2_attachment" {
  device_name  = "/dev/sdg"
  volume_id    = aws_ebs_volume.data_volume_2.id
  instance_id  = aws_instance.main.id
  skip_destroy = var.prevent_volume_destroy
}

resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"
  tags = {
    Name = "${var.project_name}-eip"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_cloudwatch_metric_alarm" "instance_cpu" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "this metric monitors ec2 cpu utilization"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  dimensions = {
    InstanceId = aws_instance.main.id
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "${var.project_name}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "this metric monitors instance status checks"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  dimensions = {
    InstanceId = aws_instance.main.id
  }
}

resource "aws_backup_vault" "main" {
  name = "${var.project_name}-backup-vault"
  tags = {
    Name = "${var.project_name}-backup-vault"
  }
}

resource "aws_backup_plan" "main" {
  name = "${var.project_name}-backup-plan"
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"
    lifecycle {
      delete_after = 30
    }
    recovery_point_tags = {
      Environment = var.environment
      BackupType  = "Automated"
    }
  }
  tags = {
    Name = "${var.project_name}-backup-plan"
  }
}

resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "main" {
  name         = "${var.project_name}-backup-selection"
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup_role.arn
  resources = [
    aws_instance.main.arn,
    aws_ebs_volume.data_volume_1.arn,
    aws_ebs_volume.data_volume_2.arn
  ]
}

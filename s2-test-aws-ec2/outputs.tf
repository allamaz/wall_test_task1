# Outputs for important resource information

output "vpc_id" {
  description = "vpc id"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "vpc cidr"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "public subnets IDs"
  value       = aws_subnet.public[*].id
}

output "instance_id" {
  description = "ec2 instance ID"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "ec2 instance private ip"
  value       = aws_instance.main.private_ip
}

output "instance_public_ip" {
  description = "ec2 instance public elastic ip"
  value       = aws_eip.main.public_ip
}

output "instance_availability_zone" {
  description = "ec2 az"
  value       = aws_instance.main.availability_zone
}

output "security_group_id" {
  description = "sec.grp. id"
  value       = aws_security_group.ec2.id
}

output "ebs_volume_1_id" {
  description = "ebs vol 1 id"
  value       = aws_ebs_volume.data_volume_1.id
}

output "ebs_volume_2_id" {
  description = "ebs vol 2 id"
  value       = aws_ebs_volume.data_volume_2.id
}

output "ebs_volume_1_device" {
  description = "ebs vol 1 device name"
  value       = aws_volume_attachment.data_volume_1_attachment.device_name
}

output "ebs_volume_2_device" {
  description = "ebs vol 2 device name"
  value       = aws_volume_attachment.data_volume_2_attachment.device_name
}

output "backup_vault_arn" {
  description = "backup vault arn"
  value       = aws_backup_vault.main.arn
}

output "backup_plan_id" {
  description = "backup plan id"
  value       = aws_backup_plan.main.id
}

output "ssh_connection_command" {
  description = "ssh connection"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_eip.main.public_ip}"
}

output "instance_profile_name" {
  description = "iam instance profile name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

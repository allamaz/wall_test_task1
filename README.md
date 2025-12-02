# wallester_task_1: production-like Terraform project



Objective

· Write a production-like Terraform project with the following configuration: provider AWS, region: 
eu-west-1. This project should include a highly available EC2 instance inside of VPC, 2 separate EBS 
volumes attached to it. Connection to EC2 should be possible from IP 88.196.208.91




Functional requirements:


·  VPC

·  Secret Manager (SSH keys)

·  Subnets (private/public)

·  EC2 instance

·  Elastic IP for external access

·  CIDR for internal network

·  Security groups for access restriction

·  EBS volumes



Non-functional requirements:


· IaC with Terraform

· Push the code to GitHub and share with Wallester for assessment







Evaluation:


Q: Are the requirements met?

A: Yes, please check OUTPUT_REVIEV.txt and s1* and s2* for details or run each on your own AWS account.

```sh
"s1"

Plan: 4 to add, 0 to change, 0 to destroy.

tls_private_key.keys["test1"]: Creating...
tls_private_key.keys["test1"]: Creation complete after 0s [id=9450fac460c2a9687609bb20a611c2a91691043b]
aws_key_pair.key_pairs["test1"]: Creating...
aws_secretsmanager_secret.ssh_keys["test1"]: Creating...
aws_secretsmanager_secret.ssh_keys["test1"]: Creation complete after 0s [id=arn:aws:secretsmanager:eu-west-1:866952548456:secret:test1-ssh-pair-4zkPRQ]
aws_key_pair.key_pairs["test1"]: Creation complete after 0s [id=test1]
aws_secretsmanager_secret_version.ssh_keys_version["test1"]: Creating...
aws_secretsmanager_secret_version.ssh_keys_version["test1"]: Creation complete after 0s [id=arn:aws:secretsmanager:eu-west-1:866952548456:secret:test1-ssh-pair-4zkPRQ|terraform-20251202092046973500000002]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.



"s2"
Plan: 24 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + backup_plan_id             = (known after apply)
  + backup_vault_arn           = (known after apply)
  + ebs_volume_1_device        = "/dev/sdf"
  + ebs_volume_1_id            = (known after apply)
  + ebs_volume_2_device        = "/dev/sdg"
  + ebs_volume_2_id            = (known after apply)
  + instance_availability_zone = (known after apply)
  + instance_id                = (known after apply)
  + instance_private_ip        = (known after apply)
  + instance_profile_name      = "ha-ec2-setup-ec2-profile"
  + instance_public_ip         = (known after apply)
  + public_subnet_ids          = [
      + (known after apply),
      + (known after apply),
    ]
  + security_group_id          = (known after apply)
  + ssh_connection_command     = (known after apply)
  + vpc_cidr                   = "10.0.0.0/16"
  + vpc_id                     = (known after apply)
```

Q: Does the deployment require manual steps?

A: Expected on "s2" you have already SSH keys after "s1" (e.g it was called before "s2" in your pipeline), also you have S3 bucket and DynamoDB ( it should be replace with your own in IaC config with corresponding values in 'config.tf' files). It will be used to save terraform states and locks instead of local dir.
   Check file and align 'bucket' and 'dynamodb_table' :

![Alt text](docs/dynamodb_lock_tb.jpg?raw=true "example")

![Alt text](docs/aws_s3_bucket.jpg?raw=true "example")

```sh
  backend "s3" {
    bucket         = "dev-s333-state-bucket" # <= REPLACE with yours
    key            = "prod/ec2-instance/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "tf-state-lock" # <= REPLACE with yours
  }
}
```
Or you can remove it and use your local dir instead.

### Tech.Stack

Implemented on Windows Desktop with:
- VS Code with plugins
- AWS CLI V2 (Windows)
- AWS SSM Plugin
- Terraform


AWS side:
- VPC
- EC2
- AMI
- EBS
- Security groups
- S3
- DynamoDB table
- IAM
- Secret Manager

### Installation

1) download repos and go to s1* dir

2) make init/plan/apply for s1* before s2*

2.1)
```sh
$ terraform init
$ terraform plan
$ terraform apply -auto-approve
```
NB! if necessary, e.g in pipeline save plan result to output and use it for apply

```sh
$ terraform plan -out=tfplan.bin
$ terraform apply tfplan.bin
```

3) go to s2* dir and repeat (2.1). It creates EC2 in 2 AZ, with corresponding restriction for SSH access by IP and with 2 attachable EBS volumes.

4) clean-up AWS s2* first and then s1*:

```sh
$ terraform destroy -auto-approve
```
NB! if necessary, check what will be terminated in AWS with plan destroy before:

```sh
$ terraform plan -destroy
```

![Alt text](docs/aws_destr.jpg?raw=true "example")

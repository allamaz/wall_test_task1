resource "tls_private_key" "keys" {
  for_each  = toset(var.ssh_users)
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "key_pairs" {
  for_each   = toset(var.ssh_users)
  key_name   = each.value
  public_key = tls_private_key.keys[each.key].public_key_openssh
}

resource "aws_secretsmanager_secret" "ssh_keys" {
  for_each                = toset(var.ssh_users)
  name                    = "${each.value}-ssh-pair"
  description             = "SSH pair for EC2: ${each.value} user"
  recovery_window_in_days = 0
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "ssh_keys_version" {
  for_each  = toset(var.ssh_users)
  secret_id = aws_secretsmanager_secret.ssh_keys[each.key].id
  secret_string = jsonencode({
    pem = tls_private_key.keys[each.key].private_key_pem
    pub = tls_private_key.keys[each.key].public_key_openssh
  })
}

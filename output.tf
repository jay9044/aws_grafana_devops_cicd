output "ssh_key" {
  value = aws_key_pair.tfa_ssh_key.public_key
}
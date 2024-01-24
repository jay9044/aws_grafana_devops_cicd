output "ssh_key" {
  value = aws_key_pair.tfa_ssh_key.public_key
}

output "ec2_ami" {
  value = data.aws_ami.ec2_ami
}

output "aws_instance" {
  value = aws_key_pair.tfa_ssh_key.key_name
}

output "aws_instance_pub_ip" {
  value = aws_instance.tfa_pub_server[0].public_ip
}
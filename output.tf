output "ssh_key" {
  value = aws_key_pair.tfa_ssh_key.public_key
}

output "ec2_ami" {
  value = data.aws_ami.ec2_ami
}

output "ec2_keyname" {
  value = aws_key_pair.tfa_ssh_key.key_name
}

output "ec2_pub_ips" {
  value = aws_instance.tfa_pub_server[*].public_ip
}

//key value pair structure  {}
output "ec2_pub_ips_with_tag" {
  value = { for instance in aws_instance.tfa_pub_server : instance.tags.Name => instance.public_ip }
}

output "ec2_grafana_access" {
  value = { for instance in aws_instance.tfa_pub_server : instance.tags.Name => "${instance.public_ip}:3000" }
}

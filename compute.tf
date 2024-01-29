data "aws_ami" "ec2_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "tfa_ssh_key" {
  key_name   = "tfa_ssh_key"
  public_key = file(var.ssh_pub_key_path)
}

resource "aws_instance" "tfa_pub_server" {
  //AFTER TESTING  //count  = length(local.azs)
  count             = var.testing_count
  ami               = data.aws_ami.ec2_ami.id
  subnet_id         = aws_subnet.tfa_public_subnet[count.index].id
  availability_zone = local.azs[count.index]
  key_name          = aws_key_pair.tfa_ssh_key.key_name

  vpc_security_group_ids = [aws_security_group.tfa_sg.id]
  instance_type          = var.instance_type
  root_block_device {
    volume_size = var.vol_size
  }

  // the file function only accepts one functions, so cant use .sh to pass args
  user_data = templatefile("./entry_script.tpl", { new_hostname = "tfa_pub_server-${count.index + 1}" })

  tags = {
    Name = "tfa_pub_server-${count.index + 1}"
  }
}

//Trying to avoid using local provisioner
resource "local_file" "server_ips" {
  filename = "instance_ips.txt"
  content  = join("\n", aws_instance.tfa_pub_server[*].tags.Name - aws_instance.tfa_pub_server[*].public_ip) //using widlcard since count is mentioned outside of this resource

}

resource "local_file" "server_ipsv2" {
  filename = "instance_ips_v2.txt"
  content  = join("\n", [for instance in aws_instance.tfa_pub_server : "${instance.tags.Name} - ${instance.public_ip}"])
}
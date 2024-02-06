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
  // utilising ansible for this instead
  ///user_data = templatefile("./entry_script.tpl", { new_hostname = "tfa_pub_server-${count.index + 1}" })

  tags = {
    Name = "tfa_pub_server-${count.index + 1}"
  }
}

//To avoid using provisioners
resource "local_file" "server_ipsv2" {
  depends_on = [aws_instance.tfa_pub_server]
  filename   = "aws_instance_ips.ini"
  content    = join("\n", concat(["[web_servers]"], [for instance in aws_instance.tfa_pub_server[*] : "${instance.tags.Name} ansible_host=${instance.public_ip}"]))
}


//Debating whether to ssh via ansible to seperate concerns and avoid provisioners
resource "null_resource" "grafana_install" {
  depends_on = [local_file.server_ipsv2]
  provisioner "local-exec" {
    command = "ansible-playbook -i aws_instance_ips.ini --user ubuntu --key-file ${var.ssh_priv_key_path} playbooks/grafana.yml"
  }
}
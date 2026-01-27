resource "aws_instance" "vm1" {
  ami           = "ami-0b6c6ebed2801a5cb"
  instance_type = "t3.micro"
  key_name      = "vockey"
  user_data = <<-EOF
    #!/bin/bash
    ${file("setup.sh")}
    # Creer le playbook Ansible
    cat <<EOT > /home/ubuntu/playbook.yml
    ${file("playbook.yml")}
    EOT

    # Executer le playbook
    ansible-playbook /home/ubuntu/playbook.yml
  EOF
  vpc_security_group_ids = [aws_security_group.coucou.id]
  tags = {
    Name = "vm1-test"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./labsuser.pem")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["sleep 35 && sudo cat /home/ubuntu/playbook.yml"]
  }

}

resource "aws_security_group" "coucou" {
    name        = "toto"
    description = "Security group for vm1"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
    security_group_id = aws_security_group.coucou.id
    from_port         = 22
    to_port           = 22
    ip_protocol       = "tcp"
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
    security_group_id = aws_security_group.coucou.id
    from_port         = 80
    to_port           = 80
    ip_protocol       = "tcp"
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
    security_group_id = aws_security_group.coucou.id
    from_port         = 443
    to_port           = 443
    ip_protocol       = "tcp"
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
    security_group_id = aws_security_group.coucou.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}

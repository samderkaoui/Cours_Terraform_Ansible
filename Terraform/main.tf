resource "aws_instance" "vm1" {
  ami           = "ami-0b6c6ebed2801a5cb"
  instance_type = "t3.micro"
  key_name      = "vockey"
  vpc_security_group_ids = [aws_security_group.coucou.id]
  tags = {
    Name = "vm1-test"
  }
}

resource "aws_security_group" "coucou" {
    name        = "toto"
    description = "Security group for vm1"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  region = "eu-central-1"
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.try.id
}


resource "aws_instance" "app_server" {
  ami             = "ami-04e601abe3e1a910f"
  instance_type   = "t2.large"
  security_groups = [aws_security_group.allow_inbound.name]
  key_name        = aws_key_pair.user.key_name

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = var.servername
  }
}


resource "aws_eip" "try" {
  vpc = true
}


resource "aws_key_pair" "user" {
  key_name   = var.keyname
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_security_group" "allow_inbound" {
  name        = var.sgname
  description = "Allow inbound traffic"

  #tls
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TCP on Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }

  #ssh
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sgname
  }
}


output "static_ip" {
  value = aws_eip.try.public_ip
}
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "MainVpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  cidr_block        = var.public_subnet_a_cidr
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "PublicSubnet-A"
  }
}

resource "aws_subnet" "private_subnet_a" {
  cidr_block        = var.private_subnet_a_cidr
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "PrivateSubnet-A"
  }
}

resource "aws_subnet" "public_subnet_b" {
  cidr_block        = var.public_subnet_b_cidr
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "PublicSubnet-B"
  }
}

resource "aws_subnet" "private_subnet_b" {
  cidr_block        = var.private_subnet_b_cidr
  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "PrivateSubnet-B"
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "alb-security-group"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port = 80
    to_port   = 80

    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0

    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "ec2-security-group"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port = 80
    to_port   = 80

    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port = 0
    to_port   = 0

    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64"]
  }
}

resource "aws_key_pair" "my-ssh-key" {
  key_name = "def-key"

  public_key = file("~/.ssh/def-key.pub")
}

resource "aws_launch_template" "nginx_lt" {
  name_prefix   = "nginx-template-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.my-ssh-key.key_name

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(templatefile("${path.module}/scripts/userdata.sh", {
    NGINX_CONF = file("${path.module / templates / nginx.conf}")
  }))
}
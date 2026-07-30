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

resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "MainIGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }

  tags = {
    Name = "MainIGW"
  }
}

resource "aws_route_table_association" "pub_a_assoc" {
  subnet_id = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_b_assoc" {
  subnet_id = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
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
    NGINX_CONF = file("${path.module/templates/nginx.conf}")
  }))
}

resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

resource "aws_lb" "web_alb" {
  name               = "nginx-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
}

resource "aws_autoscaling_group" "nginx_asg" {
  vpc_zone_identifier = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  desired_capacity = 2
  max_size         = 4
  min_size         = 2

  target_group_arns = [aws_lb_target_group.nginx_tg.arn]

  launch_template {
    id      = aws_launch_template.nginx_lt.id
    version = "$Latest"
  }
}

resource "aws_route53_zone" "main_zone" {
  name = "hega.pp.ua"
}
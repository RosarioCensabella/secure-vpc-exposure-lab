data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "al2023-ami-2023.*-kernel-6.1-x86_64"
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_app_a.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  user_data                   = file("${path.module}/../app/user-data.sh")

  tags = {
    Name = "secure-vpc-app-a"
    Role = "Private Application Instance"
  }
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_app_b.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  user_data                   = file("${path.module}/../app/user-data.sh")

  tags = {
    Name = "secure-vpc-app-b"
    Role = "Private Application Instance"
  }
}

resource "aws_lb_target_group_attachment" "app_a" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_a.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "app_b" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_b.id
  port             = 8080
}
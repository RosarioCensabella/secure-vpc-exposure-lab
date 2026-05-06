resource "aws_lb" "app" {
  name               = "secure-vpc-exposure-lab-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "secure-vpc-exposure-lab-alb"
    Role = "Public Application Entry Point"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "secure-vpc-exposure-lab-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "secure-vpc-exposure-lab-tg"
    Role = "Private Application Target Group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "secure-vpc-exposure-lab-http-listener"
  }
}
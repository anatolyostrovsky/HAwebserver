
# Highly Available Web Server 
# Any region
# Default VPC

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.4.20240513.0-kernel-6.1-x86_64*"]
  }
}

resource "aws_security_group" "new_server_sg" {
  name        = "Dynamic Security Group"
  description = "web Server Security Group"




  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "New Server SG"
    Owner = "Anatolijs Ostrovskis"
  }
}



resource "aws_launch_configuration" "new_server" {
  name            = "HighlyAvailableWebServer"
  image_id        = data.aws_ami.latest-amazon-linux-image.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.new_server_sg.id]
  user_data       = file("user-data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "new_server_asg" {
  name                 = "HighlyAvailableWebServerASG"
  launch_configuration = aws_launch_configuration.new_server.name
  min_size             = 2
  max_size             = 4
  min_elb_capacity     = 2
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.new_server_elb.name]

  dynamic "tag" {
    for_each = {
      Name   = "WebServer-ASG"
      Owner  = "Anatolijs Ostrovskis"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_elb" "new_server_elb" {
  name               = "NewServerELB"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.new_server_sg.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "NewServerELB"
  }

}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}


output "elb_url" {
  value = "aws_elb.new_server_elb.dns_name"
}

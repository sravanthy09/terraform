
/*

1. This code will on the latest terraform (0.11) and assuming region us-east-1
2. Some used values like vpc-id, subnets are not real place change them according to need
3. provider (access key and secret keys are not defining here). please use/write sperate provider.tf file
*/

# Creating a security Group

resource "aws_security_group" "Nginx_Sg" {
  name        = "Nginx_Sg"
  description = "Allow traffic from 80 and 443 ports"
  vpc_id      = "vpc-id12345" # place the vpc id here

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # add a differe CIDR block here if needed
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # add a differe CIDR block here if needed
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {

        Name = "Nginx_Security_Group"
  }
}

# creating a ELB

resource "aws_elb" "Nginx_elb" {
  name               = "Nginx_elb"
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

# uncomment this section and place a valid certname if you want to run your app on 443 port

  /*

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::9999999999:server-certificate/certNamehere" # place a valid cert name
  }
*/

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
   security_groups = [
    "${aws_security_group.Nginx_Sg.id}",
  ]

  subnets = [ "${aws_subnet-1.id}", "${aws_subnet-2.id}" ]



  tags = {
    Name = "Nginx_Loadbalancer"
  }
}

# Creating launch configuration

resource "aws_launch_configuration" "ngnix" {
  name          = "nginx_cluster"
  image_id      = "ami-0e1a402b42ec0ac8d" # ubuntu ami for us-east-1
  instance_type = "t2.micro"
  user_date = <<-EOF
  #!/bin/bash
  apt-get update
  apt-get install nginx -y
  EOF

  tags = {
           Name = "Nginx_launch_configuration"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# creating auto scaling group

resource "aws_autoscaling_group" "Nginx_ASG" {
  name                      = "Nginx_ASG"
  max_size                  = 3
  min_size                  = 3
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 3
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.ngnix.name}"
  availability_zones = [ "us-east-1a", "us-east-1b", "us-east-1c" ]
  vpc_zone_identifier       = ["${aws_subnet-1.id}", "${aws_subnet-2.id}"] # place real subnetes here
  load_balancers = [
    "${aws_elb.Nginx_elb.name}"
  ]

  tags = {

      Name = "Nginx_Autoscaling _Group"
  }


}


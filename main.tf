resource "aws_instance" "my_frist_test" {
  ami           = "ami-0651f1bab1a933ae5"
  instance_type = "t2.micro"
#
  tags = {
    Name = "centos"
  } 
}
 #1. create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
#
  tags = {
    Name = "production"
  }
}
#2. create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "aws_vpc.prod-vpc.id"
}
#
# 3. Create custome Route table
#
resource "aws_route_table" "prod-rout-table" {
  vpc_id = "aws_vpc.prod-vpc.id"
#
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "aws_internet_gateway.gw.id"
    }
#
    route {
      ipv6_cidr_block        = "::/0"
      egress_only_gateway_id = "aws_internet_gateway.gw.id"
    }
#
  tags = {
    Name = "prod"
  }
}
# 4. create subnet
resource "aws_subnet" "subnet-1" {
  vpc_id     = "aws_vpc.prod-vpc.id"
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
#
  tags = {
    Name = "prod-subnet"
  }
}
#
# 5. Associtae subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = "aws_subnet.subnet-1.id"
  route_table_id = "aws_route_table.prod-rout-table.id"
}
#
# 6. Security Policy
#
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = "aws_vpc.prod-vpc.id"
#
  ingress {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
#
  ingress {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
      description      = "ssh from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
#
#
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
#
  tags = {
    Name = "allow_web"
  }
}
#
# 7. create network interface
resource "aws_network_interface" "prod-network" {
  subnet_id       = "aws_subnet.subnet-1.id"
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
#
}
# 8. create elastic ip
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = "aws_network_interface.prod-network.id"
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
#
# 9. create ubuntu server 
resource "aws_instance" "web_sserver" {
  ami = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "window_key"
#
  network_interface {
    device_index = 0
    network_interface_id = "aws_network_interface.prod-network.id"
  }
#
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install apache2 -y
              sudo systemctl start apache2
              sudo systemctl enabled apache2
              sudo bash -c "echo my very first web server > /var/www/html/index.html" 
              echo "apache server has been installed"
              EOF
  tags = {
    name = "web_server"
  }
#
  
}
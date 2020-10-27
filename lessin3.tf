
provider "aws" {
  access_key = file("./access_key.em")
  secret_key = file("./secret_key.em")
  region     = "eu-central-1"
}

#create one virtual_machine
resource "aws_instance" "one" {
  ami                    = "ami-0c960b947cbb2dd16"
  instance_type          = "t2.micro"
  availability_zone      = "eu-central-1"
  key_name               = "Frankfurt-"
  vpc_security_group_ids = [aws_security_group.allow_https.id]
  user_data              = file("/script/httpd.sh")
  tags = {
    Name = "my-one-server"
  }
  /*
#Block delete mashine
  lifecycle {
    prevent_destroy = yes
  }
*/
}

#create static ip
resource "aws_eip" "myoneip" {
  instance = aws_instance.one.id
}

#create two virtual_machine
resource "aws_instance" "two" {
  ami                    = "ami-0c960b947cbb2dd16"
  instance_type          = "t2.micro"
  availability_zone      = "eu-central-1"
  key_name               = "Frankfurt-"
  vpc_security_group_ids = [aws_security_group.allow_https.id]
  user_data              = file("/script/httpd.sh")
  tags = {
    Name = "my-two-server"
  }
  /*
  #Block delete mashine
  lifecycle {
    prevent_destroy = folce
  }
*/
}
#create static ip
resource "aws_eip" "two" {
  instance = aws_instance.two.id
}
#add web and ssh port
resource "aws_security_group" "allow_https" {
  name = "allow_tls"

  dynamic "ingress" {
    for_each = ["80", "443", "22", "1505"]
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
    Name = "allow_https"
  }
}
resource "aws_vpc" "test_vpc" {
  cidr_block                       = "10.0.0.0/16"
  instance_tenancy                 = "default"
  enable_dns_hostnames             = "false"
  enable_dns_support               = "true"
  enable_classiclink               = "false"
  enable_classiclink_dns_support   = "false"
  assign_generated_ipv6_cidr_block = "false"
  tags = {
    Name = "test_vpc"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "test_cidr_1" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  cidr_block = "10.1.0.0/16"
}

resource "aws_vpc_ipv4_cidr_block_association" "test_cidr_2" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  cidr_block = "10.2.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  cidr_block = "${cidrsubnet(aws_vpc_ipv4_cidr_block_association.test_cidr_2.cidr_block, 12, 0)}"
  tags = {
    Name = "2a_private"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.test_vpc.id}"
  cidr_block = "${cidrsubnet(aws_vpc_ipv4_cidr_block_association.test_cidr_2.cidr_block, 12, 1)}"
  tags = {
    Name = "2a_public"
  }
}

provider "aws" {
	region  = "ap-south-1"
	profile = "samarth"
}

resource "aws_vpc" "samarthvpc" {
    cidr_block = "192.169.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    tags = {
        Name = "samarthvpc"
  }
}

resource "aws_subnet" "sam-subnet" {
    vpc_id = "${aws_vpc.samarthvpc.id}"
    cidr_block = "192.169.0.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "sam-subnet"
  }  
}

resource "aws_internet_gateway" "sam-igw" {
    vpc_id = "${aws_vpc.samarthvpc.id}"
    tags = {
        Name = "sam-igw"
  }
}

resource "aws_route_table" "sam-rt" {
    vpc_id = "${aws_vpc.samarthvpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.sam-igw.id}"
    }
    tags = {
        Name = "sam-rt"
    }
  
}

resource "aws_route_table_association" "rta" {
    subnet_id = "${aws_subnet.sam-subnet.id}"
    route_table_id = "${aws_route_table.sam-rt.id}"

}

resource "aws_security_group" "security" {
  name        = "mysecurity"
  description = "Allow inbound traffic"
  vpc_id = "${aws_vpc.samarthvpc.id}"


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TCP"
    from_port   = 3306
    to_port     = 3306
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

resource "aws_instance" "rhat" {
    ami             = "ami-052c08d70def0ac62"
    instance_type   = "t2.micro"
    key_name        = "newaaccount"
    vpc_security_group_ids=["${aws_security_group.security.id}"]
    availability_zone = "ap-south-1a"
    subnet_id = "${aws_subnet.sam-subnet.id}"

    tags = {
        Name = "rhat"
    }
  
}
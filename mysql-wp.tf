provider "aws" {
	region  = "ap-south-1"
	profile = "samarth"
}

resource "aws_vpc" "samarthvpc" {
    cidr_block           = "192.169.0.0/16"
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    tags = {
        Name = "samarthvpc"
  }
}

resource "aws_subnet" "sam-subnet-public" {
    vpc_id                  = "${aws_vpc.samarthvpc.id}"
    cidr_block              = "192.169.0.0/24"
    availability_zone       = "ap-south-1a"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "sam-subnet"
  }  
}

resource "aws_subnet" "sam-subnet-private" {
    vpc_id                  = "${aws_vpc.samarthvpc.id}"
    cidr_block              = "192.169.1.0/24"
    availability_zone       = "ap-south-1b"
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
    subnet_id      = "${aws_subnet.sam-subnet-public.id}"
    route_table_id = "${aws_route_table.sam-rt.id}"

}

resource "aws_security_group" "sg_wp" {
  name = "sg_wp"
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
  tags ={
    Name= "sg_wp"
  }

}

resource "aws_security_group" "sg_mysql" {
  name   = "sg_mysql"
  vpc_id = "${aws_vpc.samarthvpc.id}"
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = ["${aws_security_group.sg_wp.id}"]
  }


 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags ={
    Name= "sg_mysql"
  }

}

resource "aws_instance" "wp-instance" {
  ami                    = "ami-000cbce3e1b899ebd"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.sam-subnet-public.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_wp.id}"]
  key_name = "newaaccount"
 tags = {
    Name= "wp-instance"
  }

}

resource "aws_instance" "mysql-instance" {
  ami                    = "ami-0019ac6129392a0f2"
  instance_type          = "t2.micro"
  subnet_id              = "${aws_subnet.sam-subnet-private.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_mysql.id}"]
  key_name = "newaaccount"
 tags = {
    Name= "mysql-instance"
  }
}
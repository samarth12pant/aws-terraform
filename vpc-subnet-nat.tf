provider "aws" {
	region  = "ap-south-1"
	profile = "samarth"
}

resource "aws_vpc" "samarthvpc" {
    cidr_block           = "192.160.0.0/16"
    instance_tenancy     = "default"
    enable_dns_hostnames = true
    tags = {
        Name = "samarthvpc"
  }
}

resource "aws_subnet" "sam-subnet-public" {
    vpc_id                  = aws_vpc.samarthvpc.id
    cidr_block              = "192.160.0.0/24"
    availability_zone       = "ap-south-1a"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "sam-subnet-public"
  }  
}

resource "aws_subnet" "sam-subnet-private" {
    vpc_id                  = "${aws_vpc.samarthvpc.id}"
    cidr_block              = "192.160.1.0/24"
    availability_zone       = "ap-south-1b"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "sam-subnet-private"
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
  name   = "sg_wp"
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

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.sam-subnet-public.id}"
  depends_on    = [aws_internet_gateway.sam-igw]

  tags = {
    Name = "gw-NAT"
  }
}

resource "aws_route_table"  "for-private-snet" {
    vpc_id = "${aws_vpc.samarthvpc.id}"

    route{
        cidr_block  = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
    }

    tags= {
        Name = "formysql"
    }
}

resource "aws_route_table_association" "nat-rt" {
    subnet_id      = "${aws_subnet.sam-subnet-private.id}"
    route_table_id = "${aws_route_table.for-private-snet.id}"
}

resource "aws_security_group" "sg-for-db" {
    name        = "for-db"
    description = "allow wp instance to contact to db"
    vpc_id      = "${aws_vpc.samarthvpc.id}"

    ingress {
        description     = "database"
        from_port       = 3306
        to_port         = 3306
        protocol        = "tcp"
        security_groups = ["${aws_security_group.sg_wp.id}"]
    }

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
    tags = {
        Name = "my-db-sg"
    }
}

resource "aws_instance" "wordpress" {
    ami                         = "ami-000cbce3e1b899ebd"
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = "${aws_subnet.sam-subnet-public.id}"
    vpc_security_group_ids      = ["${aws_security_group.sg_wp.id}"]
    key_name                    = "newaaccount"

    tags = {
        Name = "wp-instance"
    }
}

resource "aws_instance" "mysql" {
    ami                    = "ami-0019ac6129392a0f2"
    instance_type          = "t2.micro"
    subnet_id              = "${aws_subnet.sam-subnet-private.id}"
    vpc_security_group_ids = ["${aws_security_group.sg-for-db.id}"]
    key_name = "newaaccount"
    tags = {
        Name= "mysql-instance"
  }
}    
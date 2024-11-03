provider "aws" {
  region = "eu-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
}
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key"{
  key_name = "server-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC84NnrDn0ThVQ2xLYxHEsSpqMMfuo7Qos7V38geDrbt/SWboNs9MEmHzpB5iuCM5GV6Q0cDf0LRD2fB33c3ZuVq1viYVla1hOGiEOZXd/UME4KafQYuldDCkv6zPJi9/ekAhiLoYTtw6tEtopOUDNgTKO4MT2YdOhvHhpgPcXSBSx3eKDVu0fY1GLodxt0dBPVTFhbotOKRUmdA9OU+TSmkO0ZVrIhIbk1s8L/HBSvMa7XZDPSkVpGQo/5v0n4caElPNwqq5wjF2qXMRzrpVSkFtjmKQERQ0upioZh0zi2FN9QjpCCHqT/xY0Ag00KXck2OKkCPdXSmIPQ2iIe/a2IilZ4KQde1N/VS6HFEdxeIVI8NirSuSdjA4KyVRoy5T61k57d+wqerFCL7kY+Q8uMatWDLoAKBGR1XLCLyKEgWbKTsw2uIo6iD6g1F1FUe5INzRzziMPay6HO7DUIwILmEJodcnkLnng9ZxIjQ3boZiaZreRcy1/hNBZ/NxtbB2M= logan@LoganLenovo"
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = "server-key-pair"

  tags = {
    Name: "${var.env_prefix}-server"
  }
}
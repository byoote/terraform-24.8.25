resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}
resource "aws_subnet" "mtc_public_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_public"
  }
}
resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id

  tags = {
    Name = "dev-igw"
  }
}
resource "aws_route_table" "mtc_route_table" {
  vpc_id = aws_vpc.mtc_vpc.id


  tags = {
    Name = "dev-route_table"
  }
}
resource "aws_route" "mtc_route" {
  route_table_id         = aws_route_table.mtc_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id
}
resource "aws_route_table_association" "mtc-a" {
  subnet_id      = aws_subnet.mtc_public_subnet.id
  route_table_id = aws_route_table.mtc_route_table.id
}
resource "aws_security_group" "mtc_sg" {
  name        = "public_sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "okpara" {
  key_name   = "okpara-key"
  public_key = file("~/.ssh/okpara-key.pub")
}

resource "aws_instance" "mtc_instance" {
  ami           = data.aws_ami.server_ami.id
  instance_type = "t2.micro"
  key_name                    = aws_key_pair.okpara.key_name
  subnet_id                   = aws_subnet.mtc_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.mtc_sg.id]
  associate_public_ip_address = true
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }
  tags = {
    Name = "dev-instance"
  }
 
}


#creating ssh key
resource "aws_key_pair" "id_rsa" {
  key_name   = "id_rsa"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCpknEKSVxoKq1jBeHkQ1FCWLfvmBBw+yiRO4Bo/CWaw3dfPtjVZ7EVoRjRwU9pFJw6fwk54RZTgqUNire+o5CQ0QP/Ei4aNe0pWJ6fbGqH++tCwu3DkzLlUVxpXiXrmKaP+5ciahjbozJG5GwN5g4r4XLlWaxDS5RztUbB5dKlI5KLZhxO/7FyQkJHF6Ob8jhFvOgCHEGHmazmyqQHequ1t7BJ/H9DhPiyRF24DvFN5MG9pJg19y2dXotaexRiOXh0o3+e+yqGk4YHNweb1wKI63HEO9+gfltUtoMctxFWDClRDAnpg3eewqeH2F5urPLcZpNyu4fQtbVcleYcmJKnM9Svfe1/yD1udKP9MtO4YOWHxsGS5JaLnEF3FTDXkOa5Z7DUBistWsul1Rk8E08kYq2jZFnZvh7lUM2ESye75xPO1It2U+6q7jCEnruCBrY3wwPA9H5thnrkMhRlqhEMCSRjwgnqJZxPGTTGk9i7Uf2PDVlXxKZnyinmEdoPDJs= yashpareek99@MDEVPC-205"
}

# create a vpc
resource "aws_vpc" "myvpc1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "myvpc1"
  }
}

# create a vpc
resource "aws_vpc" "myvpc2" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "myvpc2"
  }
}

# create a public subnet for vpc1
resource "aws_subnet" "myvpc1_subnet_1" {
  vpc_id                  = aws_vpc.myvpc1.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a" # availability zone
  map_public_ip_on_launch = true         # public subnet
  tags = {
    Name = "myvpc1_subnet_1"
  }
}

# create a public subnet for vpc2
resource "aws_subnet" "myvpc2_subnet_1" {
  vpc_id                  = aws_vpc.myvpc2.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-west-1a" # availability zone
  map_public_ip_on_launch = true         # public subnet
  tags = {
    Name = "myvpc2_subnet_1"
  }
}

resource "aws_vpc_peering_connection" "owner" {
  vpc_id      = aws_vpc.myvpc1.id
  peer_vpc_id = aws_vpc.myvpc2.id
  auto_accept = true
  tags = {
    Name = "vpc1_to_vpc2"
  }
}

# create IGW-1(internet gateway)
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.myvpc1.id
  tags = {
    Name = "my_igw-1"
  }
}

# create IGW-2 (internet gateway)
resource "aws_internet_gateway" "igw2" {
  vpc_id = aws_vpc.myvpc2.id
  tags = {
    Name = "my_igw-2"
  }
}

# create route table for public subnet
resource "aws_route_table" "PublicRT1" {
  vpc_id = aws_vpc.myvpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }
  tags = {
    Name = "my_route_table1"
  }
}

# create route for vpc2 to vpc1
resource "aws_route" "route_1" {
  route_table_id            = aws_route_table.PublicRT1.id
  destination_cidr_block    = aws_vpc.myvpc2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
}

# create route table for public subnet
resource "aws_route_table" "PublicRT2" {
  vpc_id = aws_vpc.myvpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw2.id
  }
  tags = {
    Name = "my_route_table2"
  }
}

# create route for vpc1 to vpc2
resource "aws_route" "route_2" {
  route_table_id            = aws_route_table.PublicRT2.id
  destination_cidr_block    = aws_vpc.myvpc1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.owner.id
}

# route table association public subnet-1
resource "aws_route_table_association" "PublicRT1association" {
  subnet_id      = aws_subnet.myvpc1_subnet_1.id
  route_table_id = aws_route_table.PublicRT1.id
}

# route table association public subnet-1
resource "aws_route_table_association" "PublicRT2association" {
  subnet_id      = aws_subnet.myvpc2_subnet_1.id
  route_table_id = aws_route_table.PublicRT2.id
}

#create security group for ec2 instances
resource "aws_security_group" "security_grp_ec2_1" {
  name   = "security_grp_ec2_1"
  vpc_id = aws_vpc.myvpc1.id

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 80 # range of
    to_port     = 80 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 8080 # range of
    to_port     = 8080 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 22 # range of
    to_port     = 22 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 443 # range of
    to_port     = 443 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create security group for ec2 instances
resource "aws_security_group" "security_grp_ec2_2" {
  name   = "security_grp_ec2_2"
  vpc_id = aws_vpc.myvpc2.id

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 80 # range of
    to_port     = 80 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 8080 # range of
    to_port     = 8080 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 22 # range of
    to_port     = 22 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow http request from Load Balancer"
    protocol    = "tcp"
    from_port   = 443 # range of
    to_port     = 443 # port numbers
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ASG with Launch template-1(vpc-1)
resource "aws_launch_template" "sh_ec2_launch_templ" {
  name_prefix   = "sh_ec2_launch_templ"
  image_id      = "ami-0cbd40f694b804622" # To note: AMI is specific for each region
  instance_type = "t2.micro"
  user_data     = filebase64("user_data.sh")

  key_name = filebase64("california.pem")

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.myvpc1_subnet_1.id
    security_groups             = [aws_security_group.security_grp_ec2_1.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "vpc1-instance" # Name for the EC2 instances
    }
  }
}

resource "aws_autoscaling_group" "sh_asg_1" {
  # no of instances
  desired_capacity = 2
  max_size         = 10
  min_size         = 1


  vpc_zone_identifier = [
    aws_subnet.myvpc1_subnet_1.id,
  ]

  launch_template {
    id      = aws_launch_template.sh_ec2_launch_templ.id
    version = "$Latest"
  }
}

# ASG with Launch template-2(vpc-1)
resource "aws_launch_template" "sh_ec2_launch_temp2" {
  name_prefix   = "sh_ec2_launch_temp2"
  image_id      = "ami-0cbd40f694b804622" # To note: AMI is specific for each region
  instance_type = "t2.micro"
  user_data     = filebase64("user_data.sh")

  key_name = filebase64("california.pem")

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.myvpc2_subnet_1.id
    security_groups             = [aws_security_group.security_grp_ec2_2.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "vpc2-instance" # Name for the EC2 instances
    }
  }
}
# create autoscaling group for vpc2
resource "aws_autoscaling_group" "sh_asg_2" {
  # no of instances
  desired_capacity = 2
  max_size         = 10
  min_size         = 1

  vpc_zone_identifier = [ # Creating EC2 instances in private subnet
    aws_subnet.myvpc2_subnet_1.id,
  ]

  launch_template {
    id      = aws_launch_template.sh_ec2_launch_temp2.id
    version = "$Latest"
  }
}

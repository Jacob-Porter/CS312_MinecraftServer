# Version: 0.0.1

# provider setup
provider "aws" {
  region = "us-west-2" # Change to your preferred region
}

# SSH key pair (UPDATE PATH FOR CORRECT PK-PAIR: ~/.ssh/id_rsa.pub)
resource "aws_key_pair" "minecraft_key" {
  key_name   = "minecraft-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# VPC
resource "aws_vpc" "minecraft_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "minecraft-vpc"
  }
}

# Subnet, update if region changed...
resource "aws_subnet" "minecraft_subnet" {
  vpc_id                  = aws_vpc.minecraft_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-west-2a"

  tags = {
    Name = "minecraft-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id

  tags = {
    Name = "minecraft-igw"
  }
}

# Route Table
resource "aws_route_table" "minecraft_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }

  tags = {
    Name = "minecraft-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "minecraft_rta" {
  subnet_id      = aws_subnet.minecraft_subnet.id
  route_table_id = aws_route_table.minecraft_rt.id
}

# Security Group
resource "aws_security_group" "minecraft_sg" {
  name        = "minecraft-server-sg"
  description = "Allow inbound SSH and Minecraft"
  vpc_id      = aws_vpc.minecraft_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Minecraft port"
    from_port   = 25565
    to_port     = 25565
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
    Name = "minecraft-server-sg"
  }
}

# Elastic IP
resource "aws_eip" "minecraft_eip" {
  domain = "vpc"
}

# Network Interface with EIP
resource "aws_network_interface" "minecraft_eni" {
  subnet_id       = aws_subnet.minecraft_subnet.id
  private_ips     = ["10.0.1.100"]
  security_groups = [aws_security_group.minecraft_sg.id]
}

resource "aws_eip_association" "minecraft_eip_assoc" {
  allocation_id        = aws_eip.minecraft_eip.id
  network_interface_id = aws_network_interface.minecraft_eni.id
}

# EC2 Instance, update based on your server requirements/region...
resource "aws_instance" "minecraft_server" {
  ami                         = "ami-0b65bee2e046aec19" # Amazon Linux 2023 ARM64 in us-west-2
  instance_type               = "t4g.small"
  key_name                    = aws_key_pair.minecraft_key.key_name
  iam_instance_profile        = "LabInstanceProfile"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.minecraft_eni.id
  }

  tags = {
    Name = "MinecraftServer"
  }
}

# Use remote-exec and SSM-enabled EC2, update PK path if required...
resource "null_resource" "run_minecraft_setup" {
  provisioner "remote-exec" {
    inline = [
      "aws s3 cp s3://cs312-minecraft-server/scripts/minecraft-setup.sh /tmp/minecraft-setup.sh",
      "chmod +x /tmp/minecraft-setup.sh",
      "sudo /tmp/minecraft-setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = aws_eip.minecraft_eip.public_ip
    }
  }

  depends_on = [aws_instance.minecraft_server]
}

# Print server IP
output "minecraft_server_ip" {
  value       = aws_eip.minecraft_eip.public_ip
  description = "Public IP to connect to your Minecraft server"
}


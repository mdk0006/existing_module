provider "aws" {
  region = "us-east-1"
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr

  azs                = [var.avail_zone]
  public_subnets     = [var.subnet_cidr]
  public_subnet_tags = { Name = "${var.env_prefix}-subnet-1" }

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "${var.env_prefix}-vpc"
  }
}
#AWS Security Group
resource "aws_security_group" "sg" {
  name   = "my_sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0    # for any
    to_port     = 0    #for any
    protocol    = "-1" #for any 
    cidr_blocks = ["0.0.0.0/0"]
    # prefix_list_ids = [] fpr vpc enpoints
  }
  tags = {
    Name = "${var.env_prefix}-sg"
  }
}
data "aws_ami" "latest_amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_key_pair" "my-key" {
  key_name = "my-key"
  ##  ssh-keygen -f tf_ec2_key
  public_key = file("tf_ec2_key.pub")
}
resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.latest_amazon_linux_ami.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.sg.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my-key.key_name
  user_data                   = file("script.sh")
  tags = {
    Name = "${var.env_prefix}-ec2"
  }
}
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

############ Creating Security Group for EC2 ############
resource "aws_security_group" "web-server" {
  name        = "MyEc2server-SG"
  description = "Security for ec2 server to connect with RDS"
  ingress {
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
}

############ Creating Key pair for EC2 ############
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "whiz_key" {
  key_name   = "WhizKey"
  public_key = tls_private_key.example.public_key_openssh
}

################## Launching EC2 Instance ##################
resource "aws_instance" "web-server" {
  ami             = "ami-01cc34ab2709337aa"
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.whiz_key.key_name
  security_groups = ["${aws_security_group.web-server.name}"]
  user_data       = <<-EOF
#!/bin/bash -ex 
yum install mysql -y    
    EOF
  tags = {
    Name = "MyRdsEc2server"
  }
}

############ Creating Security Group for RDS ############
resource "aws_security_group" "rds-server" {
  name        = "rds-maz-SG-SG"
  description = "Security group for RDS Aurora"
  ingress {
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

############ Creating Amazon Aurora Cluster ############
resource "aws_rds_cluster" "aurorards" {
  cluster_identifier     = "myauroracluster"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.12.0"
  database_name          = "MyDB"
  master_username        = "WhizlabsAdmin"
  availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
  master_password        = "Whizlabs123"
  vpc_security_group_ids = [aws_security_group.rds-server.id]
  storage_encrypted      = false
  skip_final_snapshot    = true
}

############ Launching Amazon Aurora DB Instance ############
resource "aws_rds_cluster_instance" "cluster_instances" {
  count               = 2
  identifier          = "muaurorainstance${count.index}"
  cluster_identifier  = aws_rds_cluster.aurorards.id
  publicly_accessible = true
  instance_class      = "db.t3.small"
  engine              = aws_rds_cluster.aurorards.engine
  engine_version      = "5.7.mysql_aurora.2.12.0"
}


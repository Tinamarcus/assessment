data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.name_prefix}-key"
  }
}

# MongoDB VM security group
resource "aws_security_group" "mongodb_vm" {
  name        = "${var.name_prefix}-mongodb-vm-sg"
  description = "Security group for MongoDB VM - SSH exposed to internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from internet"
  }

  # Reachable from within the VPC (EKS private subnets)
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MongoDB from K8s cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-mongodb-vm-sg"
    }
  )
}

# MongoDB VM IAM role
resource "aws_iam_role" "mongodb_vm" {
  name = "${var.name_prefix}-mongodb-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-mongodb-vm-role"
    }
  )
}

resource "aws_iam_role_policy" "mongodb_vm_policy" {
  name = "${var.name_prefix}-mongodb-vm-policy"
  role = aws_iam_role.mongodb_vm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "iam:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "mongodb_vm" {
  name = "${var.name_prefix}-mongodb-vm-profile"
  role = aws_iam_role.mongodb_vm.name
}

# MongoDB EC2 instance
resource "aws_instance" "mongodb" {
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.mongodb_vm.id]
  iam_instance_profile   = aws_iam_instance_profile.mongodb_vm.name
  key_name               = aws_key_pair.main.key_name

  user_data = replace(
    file("${path.module}/../../../scripts/mongodb-setup.sh"),
    "__S3_BUCKET_NAME__",
    var.backup_bucket_name
  )
}
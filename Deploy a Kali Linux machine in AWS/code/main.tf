# -------------------------------------------------------
# Deploy a Kali Linux Machine in AWS - Main Config
# -------------------------------------------------------

# -------------------- Data Sources --------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# -------------------- VPC --------------------

resource "aws_vpc" "kali" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -------------------- Internet Gateway --------------------

resource "aws_internet_gateway" "kali" {
  vpc_id = aws_vpc.kali.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# -------------------- Public Subnet --------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.kali.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# -------------------- Route Table --------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.kali.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kali.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------- Security Group --------------------

resource "aws_security_group" "kali" {
  name        = "${var.project_name}-sg"
  description = "Security group for Kali Linux instance"
  vpc_id      = aws_vpc.kali.id

  # SSH access
  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # RDP access
  ingress {
    description = "RDP from allowed CIDR"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# -------------------- SSH Key Pair --------------------

resource "tls_private_key" "kali" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kali" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.kali.public_key_openssh

  tags = {
    Name = "${var.project_name}-key-pair"
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.kali.private_key_pem
  filename        = "${path.module}/${var.key_pair_name}.pem"
  file_permission = "0400"
}

# -------------------- IAM Role for SSM --------------------

resource "aws_iam_role" "kali_ssm" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "kali_ssm" {
  role       = aws_iam_role.kali_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "kali_ssm" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.kali_ssm.name

  tags = {
    Name = "${var.project_name}-ssm-profile"
  }
}

# -------------------- EC2 Instance --------------------

resource "aws_instance" "kali" {
  ami                    = var.kali_ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.kali.id]
  key_name               = aws_key_pair.kali.key_name
  iam_instance_profile   = aws_iam_instance_profile.kali_ssm.name

  user_data = file("${path.module}/scripts/setup.sh")

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${var.project_name}-instance"
  }
}

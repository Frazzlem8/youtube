# ------- AWS VPC DHCP Option Sets - Main -------

# -------------------- Data Sources --------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------- VPC --------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -------------------- DHCP Option Set --------------------

resource "aws_vpc_dhcp_options" "custom" {
  domain_name         = var.custom_domain_name
  domain_name_servers = var.dns_servers

  tags = {
    Name = "${var.project_name}-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "custom" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.custom.id
}

# -------------------- Networking --------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------- Route 53 Private Hosted Zone --------------------

resource "aws_route53_zone" "private" {
  name = var.custom_domain_name

  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name = "${var.project_name}-private-zone"
  }
}

resource "aws_route53_record" "kali" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "kali.${var.custom_domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.kali.private_ip]
}

resource "aws_route53_record" "target" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "target.${var.custom_domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.target.private_ip]
}

# -------------------- Security Group --------------------

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH inbound from specified CIDR and internal traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "All traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# -------------------- SSH Key --------------------

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0400"
}

# -------------------- EC2 Instances --------------------

resource "aws_instance" "kali" {
  ami                    = var.kali_ami_id
  instance_type          = var.kali_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.main.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-kali"
  }
}

resource "aws_instance" "target" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = aws_key_pair.main.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Target Instance</h1><p>Hostname: $(hostname)</p><p>IP: $(hostname -I | awk '{print $1}')</p>" > /var/www/html/index.html
  EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-target"
  }
}

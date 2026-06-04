# ------- AWS VPC Lattice - Main -------

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

data "aws_ec2_managed_prefix_list" "vpc_lattice" {
  name = "com.amazonaws.${var.aws_region}.vpc-lattice"
}

# -------------------- VPCs --------------------

resource "aws_vpc" "orders" {
  cidr_block           = var.orders_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-orders-vpc"
  }
}

resource "aws_vpc" "payments" {
  cidr_block           = var.payments_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-payments-vpc"
  }
}

# -------------------- Orders VPC Networking --------------------

resource "aws_internet_gateway" "orders" {
  vpc_id = aws_vpc.orders.id

  tags = {
    Name = "${var.project_name}-orders-igw"
  }
}

resource "aws_subnet" "orders_public" {
  vpc_id                  = aws_vpc.orders.id
  cidr_block              = var.orders_public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-orders-public-subnet"
  }
}

resource "aws_route_table" "orders_public" {
  vpc_id = aws_vpc.orders.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.orders.id
  }

  tags = {
    Name = "${var.project_name}-orders-public-rt"
  }
}

resource "aws_route_table_association" "orders_public" {
  subnet_id      = aws_subnet.orders_public.id
  route_table_id = aws_route_table.orders_public.id
}

# -------------------- Payments VPC Networking --------------------

resource "aws_internet_gateway" "payments" {
  vpc_id = aws_vpc.payments.id

  tags = {
    Name = "${var.project_name}-payments-igw"
  }
}

resource "aws_subnet" "payments_public" {
  vpc_id                  = aws_vpc.payments.id
  cidr_block              = var.payments_public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-payments-public-subnet"
  }
}

resource "aws_route_table" "payments_public" {
  vpc_id = aws_vpc.payments.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.payments.id
  }

  tags = {
    Name = "${var.project_name}-payments-public-rt"
  }
}

resource "aws_route_table_association" "payments_public" {
  subnet_id      = aws_subnet.payments_public.id
  route_table_id = aws_route_table.payments_public.id
}

# -------------------- Security Groups --------------------

resource "aws_security_group" "orders_client" {
  name        = "${var.project_name}-orders-client-sg"
  description = "Allow SSH inbound to the orders client"
  vpc_id      = aws_vpc.orders.id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-orders-client-sg"
  }
}

resource "aws_security_group" "payments_service" {
  name        = "${var.project_name}-payments-service-sg"
  description = "Allow HTTP from VPC Lattice to the payments target"
  vpc_id      = aws_vpc.payments.id

  ingress {
    description     = "HTTP from VPC Lattice"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.vpc_lattice.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-payments-service-sg"
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

resource "aws_instance" "orders_client" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.orders_public.id
  vpc_security_group_ids = [aws_security_group.orders_client.id]
  key_name               = aws_key_pair.main.key_name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-orders-client"
  }
}

resource "aws_instance" "payments_service" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.payments_public.id
  vpc_security_group_ids = [aws_security_group.payments_service.id]
  key_name               = aws_key_pair.main.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    cat > /var/www/html/index.html <<HTML
    <h1>Payments API</h1>
    <p>Reached privately through AWS VPC Lattice.</p>
    <p>Instance: $(hostname)</p>
    <p>Private IP: $(hostname -I | awk '{print $1}')</p>
    HTML
  EOF

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-payments-service"
  }
}

# -------------------- VPC Lattice --------------------

resource "aws_vpclattice_service_network" "main" {
  name      = "${var.project_name}-service-network"
  auth_type = "NONE"
}

resource "aws_vpclattice_service_network_vpc_association" "orders" {
  vpc_identifier             = aws_vpc.orders.id
  service_network_identifier = aws_vpclattice_service_network.main.id
}

resource "aws_vpclattice_service_network_vpc_association" "payments" {
  vpc_identifier             = aws_vpc.payments.id
  service_network_identifier = aws_vpclattice_service_network.main.id
}

resource "aws_vpclattice_service" "payments" {
  name      = "${var.project_name}-payments"
  auth_type = "NONE"
}

resource "aws_vpclattice_target_group" "payments" {
  name = "${var.project_name}-payments-tg"
  type = "INSTANCE"

  config {
    port           = 80
    protocol       = "HTTP"
    vpc_identifier = aws_vpc.payments.id

    health_check {
      enabled                       = true
      protocol                      = "HTTP"
      protocol_version              = "HTTP1"
      port                          = 80
      path                          = "/"
      health_check_interval_seconds = 30
      health_check_timeout_seconds  = 5
      healthy_threshold_count       = 2
      unhealthy_threshold_count     = 2
      matcher {
        value = "200"
      }
    }
  }
}

resource "aws_vpclattice_target_group_attachment" "payments" {
  target_group_identifier = aws_vpclattice_target_group.payments.id

  target {
    id   = aws_instance.payments_service.id
    port = 80
  }
}

resource "aws_vpclattice_listener" "payments_http" {
  name               = "http"
  protocol           = "HTTP"
  port               = 80
  service_identifier = aws_vpclattice_service.payments.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.payments.id
        weight                  = 100
      }
    }
  }
}

resource "aws_vpclattice_service_network_service_association" "payments" {
  service_identifier         = aws_vpclattice_service.payments.id
  service_network_identifier = aws_vpclattice_service_network.main.id
}

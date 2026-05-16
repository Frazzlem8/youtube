# -------------------------------------------------------
# Build a Custom Kali Image with EC2 Image Builder - Main Config
# -------------------------------------------------------

# -------------------- Data Sources --------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "kali_base" {
  most_recent = true
  owners      = var.base_ami_owners

  filter {
    name   = "name"
    values = [var.base_ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# -------------------- VPC --------------------

resource "aws_vpc" "builder" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -------------------- Internet Gateway --------------------

resource "aws_internet_gateway" "builder" {
  vpc_id = aws_vpc.builder.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# -------------------- Public Subnet --------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.builder.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# -------------------- Route Table --------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.builder.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.builder.id
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

resource "aws_security_group" "builder" {
  name        = "${var.project_name}-sg"
  description = "Security group for Image Builder build instances"
  vpc_id      = aws_vpc.builder.id

  # Allow all outbound (needed to pull packages during build)
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

# -------------------- IAM Role for Image Builder --------------------

resource "aws_iam_role" "image_builder" {
  name = "${var.project_name}-role"

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
    Name = "${var.project_name}-role"
  }
}

resource "aws_iam_role_policy_attachment" "image_builder_ssm" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "image_builder_ec2" {
  role       = aws_iam_role.image_builder.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_instance_profile" "image_builder" {
  name = "${var.project_name}-profile"
  role = aws_iam_role.image_builder.name

  tags = {
    Name = "${var.project_name}-profile"
  }
}

# -------------------- Image Builder Component --------------------

locals {
  component_data    = file("${path.module}/components/kali-setup.yml")
  component_hash    = parseint(substr(sha256(local.component_data), 0, 6), 16)
  component_version = var.component_version != null ? var.component_version : "1.0.${local.component_hash}"
  recipe_version    = var.image_recipe_version != null ? var.image_recipe_version : "1.0.${local.component_hash}"
}

resource "aws_imagebuilder_component" "kali_setup" {
  name        = "${var.project_name}-kali-setup"
  platform    = "Linux"
  version     = local.component_version
  description = "Installs pentesting tools, hardens SSH, and configures the Kali image"

  data = local.component_data

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-kali-setup"
  }
}

# -------------------- Image Recipe --------------------

resource "aws_imagebuilder_image_recipe" "kali" {
  name         = "${var.project_name}-recipe"
  parent_image = data.aws_ami.kali_base.id
  version      = local.recipe_version

  lifecycle {
    create_before_destroy = true
  }

  component {
    component_arn = aws_imagebuilder_component.kali_setup.arn
  }

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tags = {
    Name = "${var.project_name}-recipe"
  }
}

# -------------------- Infrastructure Configuration --------------------

resource "aws_imagebuilder_infrastructure_configuration" "kali" {
  name                          = "${var.project_name}-infra"
  instance_profile_name         = aws_iam_instance_profile.image_builder.name
  instance_types                = [var.instance_type]
  subnet_id                     = aws_subnet.public.id
  security_group_ids            = [aws_security_group.builder.id]
  terminate_instance_on_failure = true

  tags = {
    Name = "${var.project_name}-infra"
  }
}

# -------------------- Distribution Configuration --------------------

resource "aws_imagebuilder_distribution_configuration" "kali" {
  name = "${var.project_name}-dist"

  dynamic "distribution" {
    for_each = var.distribution_regions
    content {
      region = distribution.value

      ami_distribution_configuration {
        name        = "${var.project_name}-{{imagebuilder:buildDate}}"
        description = "Custom Kali Linux AMI built by EC2 Image Builder"

        ami_tags = {
          Name      = "${var.project_name}-ami"
          Project   = "Kali-Image-Builder"
          ManagedBy = "Terraform"
          BuildDate = "{{imagebuilder:buildDate}}"
        }
      }
    }
  }

  tags = {
    Name = "${var.project_name}-dist"
  }
}

# -------------------- Image Pipeline --------------------

resource "aws_imagebuilder_image_pipeline" "kali" {
  name                             = "${var.project_name}-pipeline"
  image_recipe_arn                 = aws_imagebuilder_image_recipe.kali.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.kali.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.kali.arn
  status                           = "ENABLED"

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }

  dynamic "schedule" {
    for_each = var.pipeline_schedule != "" ? [var.pipeline_schedule] : []
    content {
      schedule_expression                = schedule.value
      pipeline_execution_start_condition = "EXPRESSION_MATCH_ONLY"
    }
  }

  tags = {
    Name = "${var.project_name}-pipeline"
  }
}

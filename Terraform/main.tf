############################################
# MAIN.TF — 3-TIER WEB APPLICATION (AWS)
############################################

# --- Data Sources ---
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_caller_identity" "current" {}

resource "random_id" "snapshot_id" {
  byte_length = 4
}

# --- IAM Role for EC2 to Access SSM ---
resource "aws_iam_role" "app_role" {
  name = "flask-app-role-${random_id.snapshot_id.hex}"
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
}

resource "aws_iam_policy" "ssm_access" {
  name        = "flask-ssm-access-${random_id.snapshot_id.hex}"
  description = "Allow EC2 to read SSM parameters"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.db_host.arn,
          aws_ssm_parameter.db_user.arn,
          aws_ssm_parameter.db_password.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "flask-app-profile-${random_id.snapshot_id.hex}"
  role = aws_iam_role.app_role.name
}

# --- VPC & Networking ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "three-tier-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "three-tier-igw"
  }
}

# --- Public Subnets (for ALB + Bastion) ---
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-b"
  }
}

# --- Private App Subnets (for EC2 App Tier) ---
resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "app-subnet-a"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "app-subnet-b"
  }
}

# --- Private DB Subnets (for RDS) ---
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "db-subnet-a"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "db-subnet-b"
  }
}

# --- NAT Gateway for Private Subnets ---
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "nat-gateway"
  }
}

# --- Route Tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table for App
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private-app-rt"
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.private_app.id
}
resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.private_app.id
}

# --- Security Groups ---
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  name   = "alb-sg"
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id
  name   = "app-sg"
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id
  name   = "db-sg"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- EC2 for App Tier ---
resource "aws_instance" "app_server_a" {
  ami                    = data.aws_ami.amazon_linux_2.id # Amazon Linux 2
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app_a.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name
  depends_on             = [aws_iam_role_policy_attachment.ssm_attach, aws_ssm_parameter.db_host, aws_ssm_parameter.db_user, aws_ssm_parameter.db_password]
  user_data              = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 jq

              mkdir -p /home/ec2-user/flask-app
              cd /home/ec2-user/flask-app

              echo "${base64encode(file("${path.module}/../app/app.py"))}" | base64 -d > app.py
              echo "${base64encode(file("${path.module}/../app/requirements.txt"))}" | base64 -d > requirements.txt

              pip3 install -r requirements.txt

              REGION="${var.aws_region}"

              get_ssm_param() {
                for i in {1..5}; do
                  VAL=$(aws ssm get-parameter --name "\$1" --region "\$REGION" --with-decryption --query "Parameter.Value" --output text 2>/dev/null)
                  if [ -n "\$VAL" ]; then
                    echo "\$VAL"
                    return 0
                  fi
                  sleep 5
                done
                return 1
              }

              DB_HOST=$(get_ssm_param "/flask-app/db_host")
              DB_USER=$(get_ssm_param "/flask-app/db_user")
              DB_PASSWORD=$(get_ssm_param "/flask-app/db_password")

              cat << ENVEOF > .env
              DB_HOST=\$DB_HOST
              DB_USER=\$DB_USER
              DB_PASSWORD=\$DB_PASSWORD
              DB_NAME=flaskdb
              ENVEOF

              chmod 600 .env
              chown ec2-user:ec2-user .env app.py requirements.txt

              cat << SVCEOF > /etc/systemd/system/flaskapp.service
              [Unit]
              Description=Flask Application
              After=network.target

              [Service]
              User=ec2-user
              WorkingDirectory=/home/ec2-user/flask-app
              EnvironmentFile=/home/ec2-user/flask-app/.env
              ExecStart=/usr/local/bin/flask run --host=0.0.0.0 --port=5000
              Restart=always

              [Install]
              WantedBy=multi-user.target
              SVCEOF

              systemctl daemon-reload
              systemctl enable flaskapp
              systemctl start flaskapp
              EOF
  tags = {
    Name = "app-server-a"
  }
}

resource "aws_instance" "app_server_b" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app_b.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_profile.name
  depends_on             = [aws_iam_role_policy_attachment.ssm_attach, aws_ssm_parameter.db_host, aws_ssm_parameter.db_user, aws_ssm_parameter.db_password]
  user_data              = aws_instance.app_server_a.user_data
  tags = {
    Name = "app-server-b"
  }
}

# --- Application Load Balancer ---
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/health"
    port = "5000"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_a" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_a.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "app_b" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server_b.id
  port             = 5000
}

# --- RDS (MySQL Multi-AZ) ---
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]
}

resource "aws_db_instance" "mysql" {
  identifier                = "flask-db"
  engine                    = "mysql"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  db_name                   = "flaskdb"
  username                  = var.db_username
  password                  = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids    = [aws_security_group.db_sg.id]
  multi_az                  = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "flask-db-final-snapshot-${random_id.snapshot_id.hex}"
}

# --- SSM Parameters ---
resource "aws_ssm_parameter" "db_password" {
  name  = "/flask-app/db_password"
  type  = "SecureString"
  value = var.db_password
}
resource "aws_ssm_parameter" "db_host" {
  name  = "/flask-app/db_host"
  type  = "String"
  value = aws_db_instance.mysql.address
}
resource "aws_ssm_parameter" "db_user" {
  name  = "/flask-app/db_user"
  type  = "String"
  value = var.db_username
}

############################################
# END OF MAIN.TF
############################################

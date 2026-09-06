############################################
# Ubuntu AMI
############################################

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


############################################
# IAM Role for SSM
############################################

resource "aws_iam_role" "bastion" {
  name = "${local.env}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.env}-bastion-role"
  }
}


############################################
# SSM Policy
############################################

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role = aws_iam_role.bastion.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


############################################
# Instance Profile
############################################

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.env}-bastion-profile"

  role = aws_iam_role.bastion.name
}


############################################
# Bastion Security Group
############################################

resource "aws_security_group" "bastion" {
  name        = "${local.env}-bastion"
  description = "Security group for bastion accessed through SSM"
  vpc_id      = aws_vpc.main.id

  # No inbound rules are required.
  # Session Manager uses outbound HTTPS.

  egress {
    description = "Allow HTTPS and other outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${local.env}-bastion"
  }
}


############################################
# Bastion EC2 Instance
############################################

resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public_zone1.id

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.bastion.name

  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"

    encrypted = true

    delete_on_termination = true
  }

  tags = {
    Name = "${local.env}-bastion"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]

  user_data = <<-EOF
    #!/bin/bash
    # 1. Update system and install prerequisites
    apt-get update -y
    apt-get install -y ca-certificates curl apt-transport-https

    # 2. Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ubuntu
    usermod -aG docker ssm-user

    # 3. Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # 4. Install kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind

    # 5. Wait for Docker daemon to be fully ready
    until docker info >/dev/null 2>&1; do sleep 2; done

    # 6. Create the kind cluster
    kind create cluster

    # 7. Set up kubeconfig for the 'ubuntu' user so it works immediately upon login
    mkdir -p /home/ubuntu/.kube
    kind get kubeconfig > /home/ubuntu/.kube/config
    chown -R ubuntu:ubuntu /home/ubuntu/.kube
  EOF
}


############################################
# Outputs
############################################

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"

  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion public IPv4 address"

  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion private IPv4 address"

  value = aws_instance.bastion.private_ip
}

output "bastion_ami_id" {
  description = "Ubuntu AMI ID"

  value = data.aws_ami.ubuntu.id
}
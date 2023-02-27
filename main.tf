terraform {
  required_version = ">= 1.3.7"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
  skip_credentials_validation = var.aws_profile == ""
  skip_metadata_api_check     = var.aws_profile == ""
}

### DNS ###
data "aws_route53_zone" "domain" {
  count = var.domain != "" ? 1 : 0
  name = var.domain
}

resource "aws_route53_record" "harbor-registry" {
  count = var.dns_record != "" ? 1 : 0
  depends_on = [data.aws_route53_zone.domain, aws_instance.harbor-registry]

  name = var.dns_record
  type = "A"
  ttl  = "60"
  zone_id = "${data.aws_route53_zone.domain[0].zone_id}"

  records = [
    "${aws_instance.harbor-registry.public_ip}"
  ]
}

# Templates
data "aws_ami" "ubuntu" {
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  most_recent = true
}

# Harbor Instance
resource "aws_instance" "harbor-registry" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_size
  vpc_security_group_ids = [aws_security_group.harbor-registry.id]
  key_name = var.key_name

  tags = {
    Name = "Harbor-Registry"
  }
}

# Post-provisioning steps for Harbor Instance
resource "null_resource" "harbor-registry_preparation" {
  depends_on = [aws_route53_record.harbor-registry]
    triggers = {
        instance = "${aws_instance.harbor-registry.id}"
    }

  connection {
    host        = "${aws_instance.harbor-registry.public_ip}"
    type        = "ssh"
    user        = "ubuntu"
    timeout     = "2m"
    agent       = true
  }

  provisioner "file" {
    content     = templatefile("${path.module}/files/install_harbor.sh.tpl",
      {
        fqdn = try(aws_route53_record.harbor-registry[0].fqdn, aws_instance.harbor-registry.public_ip)
        harbor_admin_password = var.harbor_admin_password
      }
    )
    destination = "/tmp/install_harbor.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install apt-transport-https ca-certificates curl software-properties-common jq certbot python3-certbot-nginx -y",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt update -y",
      "sudo apt install docker-ce docker-compose -y",
      "sudo systemctl start docker",
      "sudo usermod -aG docker ubuntu",
      "bash /tmp/install_harbor.sh"
    ]
  }
}

# Security Group
resource "aws_security_group" "harbor-registry" {
  name        = "harbor-registry"
  description = "Allow SSH, HTTP, and HTTPS access ingress and anything egress."

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# Outputs
output "instance-connection-string" {
  value = "ssh -o StrictHostKeyChecking=no ubuntu@${aws_instance.harbor-registry.public_ip}"
}

output "harbor-registry-url" {
  value = try(
    "https://${aws_route53_record.harbor-registry[0].fqdn}",
    "http://${aws_instance.harbor-registry.public_ip}",
  )
}

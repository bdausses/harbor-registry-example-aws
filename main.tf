provider "aws" {
  region  = "us-east-1"
  profile = "org-management-bdausses"
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
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  most_recent = true
}

data "template_file" "harbor_install_script" {
  template = "${file("files/install_harbor.sh.tpl")}"
  vars = {
    fqdn = try(aws_route53_record.harbor-registry[0].fqdn, aws_instance.harbor-registry.public_ip)
  }
}

# Harbor Instance
resource "aws_instance" "harbor-registry" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.medium"
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
    content     = "${data.template_file.harbor_install_script.rendered}"
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

# ==============================================================================
# Module: Security
# Resources: Security Group for Web (80), SSL (443), SSH (22) and Egress
# ==============================================================================

resource "aws_security_group" "crm_sg" {
  name        = var.environment == "prod" ? "serphawk-crm-sg" : "serphawk-${var.environment}-sg"
  description = "Security group for SERP Hawk CRM V2"
  vpc_id      = var.vpc_id

  # HTTP Entry
  ingress {
    description = "Allow HTTP inbound from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Entry
  ingress {
    description = "Allow HTTPS inbound from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH for Administrator
  ingress {
    description = "Allow SSH inbound from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # Outbound to Internet
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "serphawk-${var.environment}-sg"
  })
}

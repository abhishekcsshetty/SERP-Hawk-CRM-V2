# ==============================================================================
# Bootstrap Infrastructure: S3 Bucket & DynamoDB for Terraform Remote State
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. S3 Bucket for Storing Remote State
resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "serphawk-tfstate-"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "SERP Hawk Terraform State Storage"
    ManagedBy   = "Terraform"
    Environment = "global"
  }
}

# 2. Enable S3 Versioning for Automated Point-in-Time State Backups
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Enable AES256 Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Strictly Block All Public Access to State Files
resource "aws_s3_bucket_public_access_block" "state_public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. DynamoDB Table for Distributed State Locking (Prevents Concurrent Runs)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "serphawk-tfstate-locks"
  billing_mode = "PAY_PER_REQUEST" # Free Tier compliant: 0 idle cost
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "SERP Hawk Terraform State Lock Table"
    ManagedBy   = "Terraform"
    Environment = "global"
  }
}

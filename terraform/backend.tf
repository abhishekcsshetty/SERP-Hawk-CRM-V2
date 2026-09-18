# ==============================================================================
# Remote State Backend Configuration (S3 + DynamoDB State Locking)
# Free Tier Compliant: S3 (5GB standard storage) + DynamoDB (PAY_PER_REQUEST, $0 idle)
# Automated versioning ensures continuous point-in-time state backups.
# DynamoDB ensures distributed state locking across team and CI/CD pipelines.
# ==============================================================================

terraform {
  backend "s3" {
    bucket         = "serphawk-tfstate-20260918080723478300000001"
    key            = "crm-v2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "serphawk-tfstate-locks"
    encrypt        = true
  }
}

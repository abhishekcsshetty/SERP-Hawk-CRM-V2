# ==============================================================================
# Centralized Locals & Dynamic Workspace Mapping
# ==============================================================================

locals {
  # Dynamically determine the active environment from terraform.workspace
  # When on 'default', fallback to 'prod'; otherwise use the workspace name (e.g. 'dev', 'stage', 'prod')
  environment = terraform.workspace == "default" ? "prod" : terraform.workspace

  # Centralized tagging applied to all AWS resources
  common_tags = {
    Project     = "SERP-Hawk-CRM-V2"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
    Repository  = "https://github.com/abhishekcsshetty/SERP-Hawk-CRM-V2"
  }

  availability_zone = "${var.aws_region}a"
}

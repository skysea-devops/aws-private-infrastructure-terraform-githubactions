
# ============================================================================
# app Encryption Key
# ============================================================================

resource "aws_secretsmanager_secret" "app_encryption_key" {
  name        = "${var.project}/${var.env}/app-encryption-key"
  description = "app encryption key for credentials (populated by GitHub Actions)"
  
  tags = merge(local.tags, {
    Name        = "${var.project}-${var.env}-app-encryption-key"
    Application = "app"
  })
}

# Placeholder version - will be replaced by GitHub Actions
resource "aws_secretsmanager_secret_version" "app_encryption_key" {
  secret_id     = aws_secretsmanager_secret.app_encryption_key.id
  secret_string = "PLACEHOLDER-REPLACE-VIA-GITHUB-ACTIONS"
  
  lifecycle {
    ignore_changes = [secret_string]  # GitHub Actions will manage actual value
  }
}

# ============================================================================
# Resource Policy - Control Access
# ============================================================================

resource "aws_secretsmanager_secret_policy" "app_encryption_key" {
  secret_arn = aws_secretsmanager_secret.app_encryption_key.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Read"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_service.arn
        }
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# Outputs
# ============================================================================

output "app_encryption_key_secret_name" {
  description = "Secrets Manager secret name for app encryption key"
  value       = aws_secretsmanager_secret.app_encryption_key.name
}

output "app_encryption_key_secret_arn" {
  description = "ARN of app encryption key secret"
  value       = aws_secretsmanager_secret.app_encryption_key.arn
}

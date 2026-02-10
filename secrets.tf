
# secrets.tf — OIDC client secret


resource "aws_secretsmanager_secret" "oidc" {
  name                    = "${var.project}/${var.env}/entra-oidc-client-secret"
  description             = "Entra ID OIDC client secret for ALB authentication"
  recovery_window_in_days = 7

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-oidc-secret" })
}

resource "aws_secretsmanager_secret_version" "oidc" {
  secret_id     = aws_secretsmanager_secret.oidc.id
  secret_string = var.entra_client_secret

  lifecycle {
    ignore_changes = [secret_string]
  }
}

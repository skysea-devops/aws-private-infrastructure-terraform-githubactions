# ============================================================================
# AMI DATA SOURCE
# ============================================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================================
# IAM ROLE FOR EC2 INSTANCE
# ============================================================================

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_service" {
  name               = "${var.project}-${var.env}-ec2-service-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

# ============================================================================
# IAM PERMISSIONS
# ============================================================================

data "aws_iam_policy_document" "ec2_permissions" {
  statement {
    sid    = "SecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      aws_secretsmanager_secret.rds_credentials.arn,
      aws_secretsmanager_secret.oidc.arn
    ]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/${var.project}-${var.env}:*"]
  }

  statement {
    sid    = "EC2DescribeTags"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2_permissions" {
  name   = "${var.project}-${var.env}-ec2-permissions"
  role   = aws_iam_role.ec2_service.id
  policy = data.aws_iam_policy_document.ec2_permissions.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_service.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ============================================================================
# IAM INSTANCE PROFILE
# ============================================================================

resource "aws_iam_instance_profile" "ec2_service" {
  name = "${var.project}-${var.env}-ec2-service-profile"
  role = aws_iam_role.ec2_service.name
  tags = local.tags
}

# ============================================================================
# EC2 INSTANCE
# ============================================================================

resource "aws_instance" "service" {
  ami                    = var.ec2_ami_id != "" ? var.ec2_ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public["0"].id
  vpc_security_group_ids = [aws_security_group.service.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_service.name

  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project          = var.project
    env              = var.env
    aws_region       = var.aws_region
    service_port     = var.service_app_port
    rds_secret_name  = aws_secretsmanager_secret.rds_credentials.name
    target_group_arn = aws_lb_target_group.service.arn
  }))

  user_data_replace_on_change = true

  tags = merge(local.tags, { Name = "${var.project}-${var.env}-service" })

  depends_on = [aws_nat_gateway.this, aws_db_instance.this]
}

# ============================================================================
# SNS TOPIC FOR ALERTS
# ============================================================================

resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.env}-alerts"
  
  tags = merge(local.tags, {
    Name = "${var.project}-${var.env}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Allow CloudWatch and EventBridge to publish
data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowCloudWatchEvents"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com", "events.amazonaws.com"]
    }
    
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# =============================================================================
# CloudWatch Monitoring
# =============================================================================
# Create CloudWatch log group for EKS control plane logs
resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-logs"
  }
}

# Create basic CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "eks_dashboard" {
  dashboard_name = "${var.cluster_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", var.cluster_name],
            [".", "cluster_total_node_count", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS Cluster Nodes"
        }
      }
    ]
  })
}

# Create basic CloudWatch alarm for cluster health
resource "aws_cloudwatch_metric_alarm" "eks_health" {
  alarm_name          = "${var.cluster_name}-health-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors EKS cluster failed nodes"
  alarm_actions       = []

  dimensions = {
    ClusterName = var.cluster_name
  }
}

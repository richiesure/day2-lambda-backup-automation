# outputs.tf - Output values after deployment

# Lambda function details
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.ec2_backup.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.ec2_backup.arn
}

# IAM role details
output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_backup_role.arn
}

# EventBridge schedule details
output "backup_schedule" {
  description = "Backup schedule (cron expression)"
  value       = aws_cloudwatch_event_rule.daily_backup.schedule_expression
}

output "backup_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_backup.name
}

# CloudWatch Log Group
output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

# Target instance info
output "target_instance_id" {
  description = "EC2 instance being backed up"
  value       = var.target_instance_id
}

# Instructions
output "next_steps" {
  description = "What to do next"
  value       = <<-EOT
    ✅ Lambda function deployed successfully!
    
    To test the backup manually:
    aws lambda invoke --function-name ${aws_lambda_function.ec2_backup.function_name} --region ${var.aws_region} response.json
    
    To view logs:
    aws logs tail ${aws_cloudwatch_log_group.lambda_logs.name} --follow --region ${var.aws_region}
    
    Backup runs daily at 2:00 AM UTC automatically.
  EOT
}

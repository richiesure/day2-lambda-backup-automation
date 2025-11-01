# main.tf - Lambda function and automation infrastructure

# Define the AWS provider
provider "aws" {
  region = var.aws_region
}

# Create IAM role for Lambda function
resource "aws_iam_role" "lambda_backup_role" {
  name = "lambda-ec2-backup-role"

  # Trust policy allowing Lambda to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Lambda-EC2-Backup-Role"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# Create IAM policy for Lambda to create snapshots
resource "aws_iam_policy" "lambda_backup_policy" {
  name        = "lambda-ec2-backup-policy"
  description = "Policy for Lambda to create EC2 snapshots"

  # Policy allowing Lambda to describe instances and create snapshots
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateSnapshot",
          "ec2:CreateTags",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })

  tags = {
    Name        = "Lambda-EC2-Backup-Policy"
    ManagedBy   = "Terraform"
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_backup_attach" {
  role       = aws_iam_role.lambda_backup_role.name
  policy_arn = aws_iam_policy.lambda_backup_policy.arn
}

# Create a zip file of the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/ec2_snapshot.py"
  output_path = "${path.module}/lambda/ec2_snapshot.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "ec2_backup" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ec2-automated-backup"
  role            = aws_iam_role.lambda_backup_role.arn
  handler         = "ec2_snapshot.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.12"
  timeout         = 60
  
  description = "Automated EC2 instance backup function"

  # Environment variables (if needed)
  environment {
    variables = {
      REGION = var.aws_region
    }
  }

  tags = {
    Name        = "EC2-Automated-Backup"
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}

# Create CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.ec2_backup.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "Lambda-Backup-Logs"
    ManagedBy   = "Terraform"
  }
}

# Create EventBridge rule to trigger Lambda daily at 2 AM UTC
resource "aws_cloudwatch_event_rule" "daily_backup" {
  name                = "daily-ec2-backup"
  description         = "Trigger EC2 backup Lambda function daily at 2 AM UTC"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = {
    Name        = "Daily-EC2-Backup-Schedule"
    ManagedBy   = "Terraform"
  }
}

# Create EventBridge target to invoke Lambda
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_backup.name
  target_id = "TriggerLambdaBackup"
  arn       = aws_lambda_function.ec2_backup.arn
}

# Give EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_backup.arn
}

# Update the existing Day 1 EC2 instance to add Backup tag
resource "aws_ec2_tag" "backup_tag" {
  resource_id = var.target_instance_id
  key         = "Backup"
  value       = "true"
}

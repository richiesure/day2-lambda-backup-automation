# Day 2: Automated EC2 Backup with Lambda & EventBridge

## Project Description
This project creates a serverless backup automation system for EC2 instances using AWS Lambda, EventBridge, and CloudWatch.

## Architecture
```
EventBridge (Cron) → Lambda Function → EC2 Snapshots
                          ↓
                    CloudWatch Logs
```

## What This Does
- **Lambda Function**: Python function that automatically creates EBS snapshots
- **EventBridge Rule**: Schedules Lambda to run daily at 2:00 AM UTC
- **IAM Role & Policy**: Provides Lambda with necessary EC2 permissions
- **CloudWatch Logs**: Tracks all backup operations
- **Automatic Tagging**: Tags EC2 instance for backup eligibility

## Components Created

### 1. Lambda Function (`ec2-automated-backup`)
- Runtime: Python 3.12
- Timeout: 60 seconds
- Triggers: EventBridge scheduled event
- Function: Creates snapshots of EC2 instances tagged with `Backup: true`

### 2. IAM Role & Policy
- Role: `lambda-ec2-backup-role`
- Permissions: EC2 describe/snapshot operations, CloudWatch logging

### 3. EventBridge Rule
- Schedule: Daily at 2:00 AM UTC
- Cron Expression: `cron(0 2 * * ? *)`

### 4. CloudWatch Log Group
- Retention: 7 days
- Logs all Lambda executions and errors

## Prerequisites
- AWS CLI configured
- Terraform installed
- Python 3.12+
- Day 1 EC2 instance running

## Files Structure
```
.
├── lambda/
│   └── ec2_snapshot.py    # Lambda function code
├── main.tf                # Main infrastructure config
├── variables.tf           # Input variables
├── outputs.tf             # Output values
└── README.md              # This file
```

## Deployment

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Review the plan
```bash
terraform plan
```

### Step 3: Deploy
```bash
terraform apply
```

## Testing the Backup

### Manual Trigger
```bash
# Invoke Lambda manually to test
aws lambda invoke \
  --function-name ec2-automated-backup \
  --region eu-west-2 \
  response.json

# View the response
cat response.json
```

### View Logs
```bash
# Tail CloudWatch logs in real-time
aws logs tail /aws/lambda/ec2-automated-backup --follow --region eu-west-2
```

### Check Snapshots
```bash
# List all snapshots created by Lambda
aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:CreatedBy,Values=Lambda-AutoBackup" \
  --region eu-west-2 \
  --query 'Snapshots[*].[SnapshotId,StartTime,State,Description]' \
  --output table
```

## How It Works

1. **EventBridge** triggers Lambda daily at 2:00 AM UTC
2. **Lambda function** queries EC2 for instances with tag `Backup: true`
3. For each matching instance, Lambda creates snapshots of all attached EBS volumes
4. Snapshots are tagged with:
   - Instance name and ID
   - Timestamp
   - CreatedBy: Lambda-AutoBackup
5. Results logged to CloudWatch

## Cost Considerations
- **Lambda**: Free tier covers 1M requests/month
- **EventBridge**: Free (1M events/month)
- **EBS Snapshots**: ~$0.05 per GB-month (incremental)
- **CloudWatch Logs**: Minimal cost for 7-day retention

## Backup Retention

This setup creates snapshots but doesn't delete old ones. For production:
- Add snapshot lifecycle policies
- Implement retention cleanup in Lambda
- Use AWS Backup service for advanced retention

## Learning Objectives
- Understand serverless automation with Lambda
- Learn IAM role and policy creation
- Master EventBridge scheduling (cron expressions)
- Practice Python boto3 for AWS automation
- Implement logging and monitoring

## Troubleshooting

### Lambda execution fails
```bash
# Check Lambda logs
aws logs tail /aws/lambda/ec2-automated-backup --region eu-west-2
```

### No snapshots created
- Verify EC2 instance has `Backup: true` tag
- Check Lambda has correct IAM permissions
- Review CloudWatch logs for errors

### EventBridge not triggering
```bash
# Check EventBridge rule status
aws events describe-rule --name daily-ec2-backup --region eu-west-2
```

## Cleanup
```bash
# Delete all snapshots first
aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:CreatedBy,Values=Lambda-AutoBackup" \
  --query 'Snapshots[*].SnapshotId' \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id

# Destroy Terraform resources
terraform destroy
```

## Next Steps - Day 3 Preview
- Container orchestration with ECS
- Application monitoring with CloudWatch dashboards
- Infrastructure alerting with SNS

---

**Author:** DevOps Learning Journey - Day 2

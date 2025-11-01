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



# DAY 2 COMPLETION SUMMARY
**Date:** November 1, 2025
**Task:** Mid-Level DevOps - Automated EC2 Backup with Lambda & CloudWatch

---

## 🎯 What I have Accomplished

### 1. **Serverless Backup Automation**
- ✅ Created Python Lambda function for automated EC2 snapshots
- ✅ Configured IAM role with least-privilege permissions
- ✅ Deployed Lambda with proper error handling and logging
- ✅ Function executes in ~831ms (highly efficient)

### 2. **Scheduled Automation**
- ✅ EventBridge rule: Daily at 2:00 AM UTC
- ✅ Cron expression: `cron(0 2 * * ? *)`
- ✅ Lambda trigger configured and tested
- ✅ Manual testing successful

### 3. **Monitoring & Alerting**
- ✅ CloudWatch Log Group (7-day retention)
- ✅ CloudWatch Alarm for Lambda errors
- ✅ Detailed execution logging
- ✅ Snapshot verification completed

### 4. **Infrastructure as Code**
- ✅ 10 Terraform resources deployed
- ✅ Version controlled on GitHub
- ✅ Proper .gitignore configuration
- ✅ Comprehensive documentation

---

## 📊 Resources Deployed

### Lambda Function
```
Function Name:    ec2-automated-backup
Runtime:          Python 3.12
Memory:           128 MB (default)
Timeout:          60 seconds
Execution Time:   ~831ms
Handler:          ec2_snapshot.lambda_handler
```

### IAM Resources
```
Role:             lambda-ec2-backup-role
Policy:           lambda-ec2-backup-policy
Permissions:      EC2 snapshots, CloudWatch logs
```

### EventBridge
```
Rule Name:        daily-ec2-backup
Schedule:         cron(0 2 * * ? *)
Status:           ENABLED
Target:           Lambda function
```

### CloudWatch
```
Log Group:        /aws/lambda/ec2-automated-backup
Retention:        7 days
Alarm:            ec2-backup-lambda-errors
Metric:           Lambda Errors > 0
```

### Snapshot Created
```
Snapshot ID:      snap-05904a373195fdb0a
State:            completed
Size:             8 GB
Volume:           vol-026842e00d82d53aa
Instance:         i-077464828f9d99024 (DevOps-Day1-WebServer)
Created:          2025-11-01 09:08:54 UTC
Tags:             Properly tagged with instance info
```

---

## 📚 Key DevOps Concepts Learned

### 1. **Serverless Computing**
- **Lambda Benefits**: No server management, pay-per-execution, auto-scaling
- **Event-Driven Architecture**: Trigger-based automation
- **Stateless Functions**: Each execution is independent
- **Cold Starts**: First execution takes longer (initialization)

### 2. **IAM Security**
- **Least Privilege Principle**: Only necessary permissions granted
- **Trust Policies**: Define who can assume the role
- **Permission Policies**: Define what actions are allowed
- **Service Roles**: Roles specifically for AWS services

### 3. **CloudWatch Monitoring**
- **Log Aggregation**: Centralized logging for debugging
- **Metrics**: Track function performance and errors
- **Alarms**: Proactive alerting for failures
- **Log Retention**: Balance cost vs. audit requirements

### 4. **Backup Strategy**
- **Automated Backups**: Eliminate human error
- **Tagging Strategy**: `Backup: true` for selective backups
- **Snapshot Lifecycle**: Incremental backups save storage
- **Disaster Recovery**: Point-in-time recovery capability

### 5. **Event-Driven Automation**
- **Cron Expressions**: Schedule-based triggers
- **EventBridge**: Central event bus for AWS services
- **Decoupled Architecture**: Lambda doesn't need to know about EventBridge

---

## 🐛 Challenges Solved

### Challenge 1: Git Bash Path Conversion
**Problem**: Git Bash auto-converted `/aws/lambda/...` to Windows paths
**Solution**: Used AWS Console for log viewing
**Lesson**: Be aware of platform-specific CLI quirks

### Challenge 2: Lambda Permissions
**Problem**: Lambda needs specific IAM permissions for EC2 operations
**Solution**: Created custom IAM policy with required actions
**Lesson**: Always follow least privilege principle

### Challenge 3: Snapshot Tagging
**Problem**: Need to identify automated snapshots vs. manual ones
**Solution**: Added comprehensive tags (CreatedBy, Timestamp, InstanceName)
**Lesson**: Proper tagging is crucial for resource management

---

## 🔍 Testing & Verification

### Manual Test Results
```bash
# Lambda invocation
aws lambda invoke --function-name ec2-automated-backup --region eu-west-2 response.json

Response:
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}

# Snapshot verification
Snapshot State: completed ✅
Snapshot Size: 8 GB
Processing Time: 831ms
```

### CloudWatch Logs Verification
```
✅ Lambda initialized: python:3.12
✅ Processing instance: i-077464828f9d99024 (DevOps-Day1-WebServer)
✅ Created snapshot: snap-05904a373195fdb0a
✅ Total snapshots: 1
✅ Duration: 831.94ms
```

---

## 💡 Real-World Application

This Day 2 task demonstrates **real mid-level DevOps responsibilities**:

1. **Automating Operational Tasks**: Eliminate manual backup processes
2. **Infrastructure as Code**: All automation is version-controlled
3. **Monitoring & Alerting**: Proactive detection of issues
4. **Cost Optimization**: Serverless = pay only for what you use
5. **Security Best Practices**: IAM roles with minimal permissions
6. **Documentation**: Clear README and inline code comments

### Production Considerations
In a real production environment, I would also:
- Add SNS topic for alarm notifications (email/Slack)
- Implement snapshot retention policy (auto-delete old snapshots)
- Add error retry logic in Lambda
- Tag snapshots with compliance/retention metadata
- Use AWS Backup service for advanced features
- Implement cross-region snapshot copies for DR
- Add Lambda function versioning and aliases

---

## 📈 Cost Analysis

### Current Setup (Monthly Estimate)
```
Lambda Executions:    30/month (daily)
Lambda Duration:      ~30 seconds/month
Lambda Cost:          $0.00 (within free tier)

EventBridge Events:   30/month
EventBridge Cost:     $0.00 (within free tier)

CloudWatch Logs:      <1 MB/month
Logs Cost:            $0.00 (minimal)

EBS Snapshots:        8 GB (incremental)
Snapshot Cost:        ~$0.40/month ($0.05/GB-month)

Total Monthly Cost:   ~$0.40
```

**Note**: Snapshots are incremental, so subsequent backups only store changed blocks.

---

## 🧹 Cleanup Instructions

**IMPORTANT**: I have Run these when done with Day 2 to avoid snapshot storage costs:
```bash
# Delete all Lambda-created snapshots
aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:CreatedBy,Values=Lambda-AutoBackup" \
  --query 'Snapshots[*].SnapshotId' \
  --output text --region eu-west-2 | \
  xargs -n1 aws ec2 delete-snapshot --snapshot-id --region eu-west-2

# Destroy all Terraform resources
terraform destroy

# Verify everything is cleaned up
terraform show
```

## 📊 Skills Acquired Today

✅ **Serverless Architecture**: Lambda functions and event-driven design
✅ **Python for AWS**: Boto3 SDK for AWS automation
✅ **IAM Management**: Roles, policies, and permissions
✅ **CloudWatch**: Logging, metrics, and alarms
✅ **EventBridge**: Scheduled automation with cron
✅ **Backup Strategies**: Automated disaster recovery
✅ **Cost Optimization**: Serverless vs. traditional servers
✅ **Monitoring**: Proactive alerting and log analysis

---

## 📝 Key Takeaways

1. **Automation is Key**: Manual backups are error-prone and forgotten
2. **Infrastructure as Code**: All automation should be version-controlled
3. **Monitoring is Critical**: You can't fix what you can't see
4. **Serverless Simplifies Ops**: No servers to patch or maintain
5. **Tag Everything**: Proper tagging enables automation and cost tracking

---

## 🎓 Mid-Level DevOps Skills Demonstrated

Today's task showcases skills expected of mid-level DevOps engineers:
- Designing serverless automation solutions
- Implementing security best practices (IAM)
- Setting up monitoring and alerting
- Writing production-quality infrastructure code
- Documenting complex systems clearly
- Cost-conscious architecture decisions

**Congratulations to me! I have completed a real-world mid-level DevOps task!** 🎊

<img width="1892" height="1032" alt="image" src="https://github.com/user-attachments/assets/2666c3d4-a19a-4e6e-94b0-d06d0e534ce9" />
<img width="1916" height="1011" alt="image" src="https://github.com/user-attachments/assets/1426437e-70a0-44ff-87d9-df5dedb115ad" />



---

**GitHub Repository**: https://github.com/richiesure/day2-lambda-backup-automation

This automation will run every night at 2 AM UTC. Monitor CloudWatch logs to ensure it continues working properly!

---

**Author:** IAMEFEMENA (Richiesure)

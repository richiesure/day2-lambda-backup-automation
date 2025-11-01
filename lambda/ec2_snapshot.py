import json
import boto3
from datetime import datetime

# Initialize AWS clients
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    """
    Lambda function to create snapshots of EC2 instances with specific tags
    """
    
    # Get all running EC2 instances with 'Backup' tag set to 'true'
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Backup', 'Values': ['true']},
            {'Name': 'instance-state-name', 'Values': ['running', 'stopped']}
        ]
    )
    
    snapshot_count = 0
    snapshot_ids = []
    
    # Loop through instances and create snapshots
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_name = 'Unknown'
            
            # Get instance name from tags
            for tag in instance.get('Tags', []):
                if tag['Key'] == 'Name':
                    instance_name = tag['Value']
                    break
            
            print(f"Processing instance: {instance_id} ({instance_name})")
            
            # Create snapshot for each volume attached to the instance
            for volume in instance.get('BlockDeviceMappings', []):
                volume_id = volume['Ebs']['VolumeId']
                
                # Create timestamp for snapshot description
                timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
                description = f"Automated backup of {instance_name} ({instance_id}) - {timestamp}"
                
                # Create the snapshot
                snapshot = ec2.create_snapshot(
                    VolumeId=volume_id,
                    Description=description,
                    TagSpecifications=[
                        {
                            'ResourceType': 'snapshot',
                            'Tags': [
                                {'Key': 'Name', 'Value': f"{instance_name}-backup-{timestamp}"},
                                {'Key': 'InstanceId', 'Value': instance_id},
                                {'Key': 'InstanceName', 'Value': instance_name},
                                {'Key': 'CreatedBy', 'Value': 'Lambda-AutoBackup'},
                                {'Key': 'Timestamp', 'Value': timestamp}
                            ]
                        }
                    ]
                )
                
                snapshot_id = snapshot['SnapshotId']
                snapshot_ids.append(snapshot_id)
                snapshot_count += 1
                
                print(f"Created snapshot {snapshot_id} for volume {volume_id}")
    
    # Prepare response
    response = {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Successfully created {snapshot_count} snapshots',
            'snapshot_ids': snapshot_ids
        })
    }
    
    print(f"Total snapshots created: {snapshot_count}")
    return response

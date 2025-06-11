# import boto3
# from datetime import datetime, timezone

# ec2 = boto3.client('ec2')

# def lambda_handler(event, context):
#     now = datetime.now(timezone.utc)

#     response = ec2.describe_instances(Filters=[
#         {'Name': 'tag-key', 'Values': ['expire_at']},
#         {'Name': 'instance-state-name', 'Values': ['running', 'pending']}
#     ])

#     to_terminate = []

#     for reservation in response['Reservations']:
#         for instance in reservation['Instances']:
#             instance_id = instance['InstanceId']
#             tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
#             expire_str = tags.get('expire_at')

#             if expire_str:
#                 try:
#                     expire_time = datetime.fromisoformat(expire_str.replace('Z', '+00:00'))
#                     if now >= expire_time:
#                         to_terminate.append(instance_id)
#                 except Exception as e:
#                     print(f"Invalid date format for {instance_id}: {expire_str}")

#     if to_terminate:
#         print(f"Terminating instances: {to_terminate}")
#         ec2.terminate_instances(InstanceIds=to_terminate)
#     else:
#         print("No instances to terminate.")

# output "ec2_public_ip" {
#   description = "Public IP of the EC2 instance to connect via SSH"
#   value       = aws_launch_template.example_server.public_ip
# }

output "public_ip" {
  value = aws_instance.example_instance.public_ip
}

output "ec2_public_ip" {
  value = aws_instance.example_instance.public_ip
}

output "jenkins_ec2_ip" {
  value = aws_instance.example_instance.public_ip
}
output "instance_profile" {
  value = aws_instance.example_instance.iam_instance_profile
}

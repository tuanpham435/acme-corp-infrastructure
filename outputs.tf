# outputs.tf
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "elastic_ip" {
  description = "Elastic IP address assigned to the instance"
  value       = aws_eip.instance_eip.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/${var.key_name}.pem ec2-user@${aws_eip.instance_eip.public_ip}"
}
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web-server.id
}
output "cluster_endpoint" {
  value = aws_rds_cluster.aurorards.endpoint
}
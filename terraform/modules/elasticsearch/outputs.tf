output "arn" {
  description = "ARN of the elasticsearch domain"
  value       = aws_elasticsearch_domain.es.arn
}

output "endpoint" {
  description = "Endpoint to use to connect to elasticsearch"
  value       = aws_elasticsearch_domain.es.endpoint
}

output "kibana" {
  description = "Endpoint to use to connect to kibana"
  value       = aws_elasticsearch_domain.es.kibana_endpoint
}


resource "aws_security_group" "elasticsearch" {
  name        = "${var.domain}-elasticsearch"
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${data.aws_vpc.selected.cidr_block}",
    ]
  }

  tags = var.tags
}

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.domain
  elasticsearch_version = var.elasticsearch_version

  cluster_config {
    instance_type            = var.instance_type
    instance_count           = var.instance_count
    dedicated_master_enabled = false
  }

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.elasticsearch.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "es:*",
        "Principal": "*",
        "Effect": "Allow",
        "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.domain}/*"
      }
    ]
  }
  EOF

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = merge(var.tags, {
    Domain = var.domain
  })

  depends_on = [
    aws_iam_service_linked_role.es
  ]
}


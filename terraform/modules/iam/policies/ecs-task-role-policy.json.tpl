{
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "es:*"
            ],
            "Resource": [
                "${elasticsearch_domain_arn}"
            ]
        }
    ]
}


variable "zone_id" {
  type = string
}

variable "domain" {
  type = string         
}

variable "index_url" {
  type = string         
}

variable "error_url" {
  type = string
}

## 1. Create an S3 Bucket with public access

resource "aws_s3_bucket" "vanity" {
  bucket = var.domain
  acl    = "public-read"
  region = "us-east-1"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Sid = "PublicReadForGetBucketObjects"
        Principal = {
          AWS = "*"
        }
        Resource = "arn:aws:s3:::${var.domain}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.vanity.id
  acl          = "public-read"
  key          = "index.html"
  content_type = "text/html; charset=utf-8"

  content = <<EOF
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; url=${var.index_url}">
  </head>
  <body>
  </body>
</html>
EOF

}

resource "aws_s3_bucket_object" "error" {
  bucket       = aws_s3_bucket.vanity.id
  acl          = "public-read"
  key          = "error.html"
  content_type = "text/html; charset=utf-8"

  content = <<EOF
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="refresh" content="0; url=${var.error_url}">
  </head>
  <body>
  </body>
</html>
EOF

}


## 2. Creating and validating a certificate

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain
  validation_method = "DNS"
}

resource "aws_route53_record" "certificate" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}



## 3. Creating a CloudFront distribution 

resource "aws_cloudfront_distribution" "vanity" {
  origin {
    domain_name = aws_s3_bucket.vanity.bucket_domain_name
    origin_id   = var.domain
  }

  aliases = [var.domain]

  enabled             = true
  default_root_object = "index.html"

  // All values are defaults from the AWS console.
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.domain
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
}

resource "aws_route53_record" "vanity" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.vanity.domain_name
    zone_id                = aws_cloudfront_distribution.vanity.hosted_zone_id
    evaluate_target_health = false
  }
}

output "bucket_id" {
  value = aws_s3_bucket.vanity.id
}

variable "bucket_id" {
  type = string
}

variable "root_path" {
  type = string
}

variable "github_user" {
  type = string
}

variable "github_repository" {
  type = string
}

resource "aws_s3_bucket_object" "project" {
  bucket       = var.bucket_id
  acl          = "public-read"
  key          = "api"
  content_type = "text/html; charset=utf-8"

  content = <<EOF
<!DOCTYPE html>
<html>
  <head>
    <meta name=go-import content='${var.root_path} git git+ssh://git@github.com/${var.github_user}/${var.github_repository}.git'>
  </head>
  <body>
  </body>
</html>
EOF

}

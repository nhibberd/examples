An example configuring a vanity URL using Terraform and AWS. (Not all of these steps apply to everyone)

  1. Creating an S3 Bucket with public access

  2. Creating and validating a certificate

  3. Creating a CloudFront distribution 

```tf
module "vanity" {
  source    = "."     
  zone_id   = "..."
  domain    = "go.nhibberd.io"
  index_url = "https://nhibberd.io/"
  error_url = "https://nhibberd.io/notfound"
}
```

  4. Defining your project(s) vanity url

```tf
module "examples" {
  bucket_id         = module.vanity.bucket_id
  root_path         = "go.nhibberd.io/examples"
  github_user       = "nhibberd"
  github_repository = "examples"
}

module "private" {
  bucket_id         = module.vanity.bucket_id
  root_path         = "go.nhibberd.io/private"
  github_user       = "nhibberd"
  github_repository = "private"
}
```

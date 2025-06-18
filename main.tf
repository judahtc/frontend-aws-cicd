module "s3_cf_route53" {
  source = "./modules"

  full_repository_id = var.full_repository_id
  aws_region         = var.aws_region
  git_branch         = var.git_branch
  bucket_name        = var.bucket_name
  env                = var.env
  connectionArn      = var.connectionArn
  cloudfront_description = var.cloudfront_description
  alternate_domain = var.alternate_domain
  acm_certificate_arn = var.acm_certificate_arn
  origin_access_identity = var.origin_access_identity
}
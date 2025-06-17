module "s3_cf_route53" {
  source = "./modules"

  full_repository_id = var.full_repository_id
  aws_region         = var.aws_region
  git_branch         = var.git_branch
  bucket_name        = var.bucket_name
  env                = var.env
  connectionArn = var.connectionArn

}
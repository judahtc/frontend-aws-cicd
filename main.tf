module "s3_cf_route53" {
  source = "./modules"

  full_repository_id = ""
  aws_region = ""
  git_branch = ""
  bucket_name = ""
  env = ""
}
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "git_branch" {
  description = "Git branch to be used"
  type        = string
}

variable "full_repository_id" {
  description = "Full GitHub repository ID (e.g., org/repo)"
  type        = string
}
variable "connectionArn" {
  description = "aws github connector ARN from aws"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "app" {
  description = "Application name"
  type        = string
  default     = ""
}

variable "version_number" {
  description = "Version number"
  type        = string
  default     = ""
}

variable "cloudfront_description" {
  description = "Description for the CloudFront distribution"
  type        = string
}

variable "alternate_domain" {
  description = "Alternate domain name (CNAME) for the CloudFront distribution (e.g. frontend.claxonfintech.com)"
  type        = string
}

variable "origin_access_identity" {
  description = "CloudFront origin access identity ID (e.g. origin-access-identity/cloudfront/E34JASDR0BUABPTSHSAGS)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront distribution"
  type        = string
}


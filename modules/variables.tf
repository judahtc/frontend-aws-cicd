variable "aws_region" {

}

variable "bucket_name" {

}

variable "git_branch" {

}
variable "connectionArn" {

}
variable "cloudfront_description" {

}
variable "alternate_domain" {

}
variable "origin_access_identity" {

}


variable "acm_certificate_arn" {

}
variable "backend_url" {

}

variable "full_repository_id" {

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

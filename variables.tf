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

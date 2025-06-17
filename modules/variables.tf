variable "aws_region" {

}

variable "bucket_name" {

}

variable "git_branch" {

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

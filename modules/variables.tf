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
  default     = ""
}

variable "app" {
  description = "Application name"
  type        = string
  default     = ""
}

variable "version" {
  description = "Version number"
  type        = string
  default     = ""
}

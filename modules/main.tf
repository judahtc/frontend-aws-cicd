provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "s3_website" {
  bucket = var.bucket_name
  
  tags = {
    env     = var.env
    app     = var.app
    version = var.version_number

  }





}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.s3_website.id
  block_public_policy = false
  
}
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = aws_s3_bucket.s3_website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.s3_website.arn}/*"
      }
    ]
  })
}



resource "aws_s3_bucket_website_configuration" "s3_website_config" {
  bucket = aws_s3_bucket.s3_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }


}


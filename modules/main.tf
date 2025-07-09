provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
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
  bucket                  = aws_s3_bucket.s3_website.id
  block_public_policy     = false
  block_public_acls       = false
  ignore_public_acls      = false
  restrict_public_buckets = false

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
      },

      {
        "Sid" : "AllowCloudFrontServicePrincipal",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${var.bucket_name}/*",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceArn" : "arn:aws:cloudfront::165194454526:distribution/*"
          }
        }
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

resource "aws_iam_role" "frontend_build_role" {
  name = "frontend-build-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "frontend_build_policy" {
  role = aws_iam_role.frontend_build_role.name

  name = "frontend-build-policy"


  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::*",

        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}





resource "aws_codebuild_project" "lambda_build_project" {
  name         = "${var.bucket_name}-build"
  service_role = aws_iam_role.frontend_build_role.arn

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda_pipeline_policy_attach" {
  role       = aws_iam_role.frontend_pipeline_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}




resource "aws_iam_role_policy_attachment" "pipeline_codebuild_dev_access" {
  role       = aws_iam_role.frontend_pipeline_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

resource "aws_iam_role" "frontend_pipeline_iam_role" {
  name = "frontend-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "frontend_pipeline_policy" {
  name = "frontend-pipeline-policy"
  role = aws_iam_role.frontend_pipeline_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Allow access to CodeStar connections (GitHub)
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = "*" # Can be restricted to specific connection ARN
      },

      # Allow access to artifacts bucket (e.g., ${var.bucket_name}-pipeline)
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketVersioning"
        ],
        Resource = [
          "arn:aws:s3:::*",

        ]
      },

      # Allow CodePipeline to trigger CodeBuild
      {
        Effect = "Allow",
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        Resource = "*"
      },

      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}


resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "${var.bucket_name}-${var.aws_region}-pipeline-artifacts"
  force_destroy = true
}


resource "aws_codepipeline" "frontend_codepipeline" {
  name     = "${var.bucket_name}-pipeline"
  role_arn = aws_iam_role.frontend_pipeline_iam_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        FullRepositoryId = var.full_repository_id
        BranchName       = var.git_branch
        ConnectionArn    = var.connectionArn

      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.lambda_build_project.name


        EnvironmentVariables = jsonencode([

          {
            name  = "MODE"
            value = "prod"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }


  stage {
    name = "Deploy"

    action {
      name            = "DeployToS3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = var.bucket_name
        Extract    = "true"
      }
    }
  }
}

resource "aws_cloudfront_distribution" "claxon_frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.cloudfront_description
  default_root_object = "index.html"

  aliases = [var.alternate_domain]

  origin {
    domain_name = aws_s3_bucket.s3_website.bucket_regional_domain_name
    origin_id   = "S3Origin"

    origin_access_control_id = var.origin_access_identity
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"
    ]

    cached_methods = [
      "GET", "HEAD"
    ]

    compress = true

    forwarded_values {
      query_string = false

      headers = [
        "Authorization",
        "Origin",
        "Accept",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers"
      ]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class  = "PriceClass_All"
  http_version = "http2"


  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  tags = {
    env     = var.env
    app     = var.app
    version = var.version_number
  }
}

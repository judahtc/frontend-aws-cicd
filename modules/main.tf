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
          "arn:aws:s3:::${var.bucket_name}-pipeline",
          "arn:aws:s3:::${var.bucket_name}-pipeline/*"
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


resource "aws_codepipeline" "frontend_codepipeline" {
  name     = "${var.bucket_name}-pipeline"
  role_arn = aws_iam_role.frontend_pipeline_iam_role.arn

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
            name  = "AWS_ACCOUNT_ID"
            value = data.aws_caller_identity.current.account_id
            type  = "PLAINTEXT"
          },
          {
            name  = "AWS_DEFAULT_REGION"
            value = var.aws_region
            type  = "PLAINTEXT"
          },
          {
            name  = "IMAGE_REPO_NAME"
            value = "${var.bucket_name}_repo"
            type  = "PLAINTEXT"
          },
          {
            name  = "IMAGE_TAG"
            value = "latest"
            type  = "PLAINTEXT"
          },
          {
            name  = "FUNCTION_NAME"
            value = var.bucket_name
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


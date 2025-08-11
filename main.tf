provider "aws" {
  region = "us-east-1"
}

variable "create_bucket" {
  default = true
}

variable "create_role" {
  default = true
}

variable "existing_bucket_name" {
  default = "my-lambda-code-bucket-xml-feed"
}

variable "existing_role_name" {
  default = "lambda_s3_role"
}

# Create bucket only if needed
resource "aws_s3_bucket" "api_bucket" {
  count  = var.create_bucket ? 1 : 0
  bucket = var.existing_bucket_name
}

# If bucket already exists, fetch it
data "aws_s3_bucket" "existing" {
  count  = var.create_bucket ? 0 : 1
  bucket = var.existing_bucket_name
}

# Local variables for bucket name & ARN
locals {
  bucket_name = var.create_bucket ? aws_s3_bucket.api_bucket[0].bucket : data.aws_s3_bucket.existing[0].bucket
  bucket_arn  = var.create_bucket ? aws_s3_bucket.api_bucket[0].arn    : data.aws_s3_bucket.existing[0].arn
}

# Create IAM role only if needed
resource "aws_iam_role" "lambda_role" {
  count = var.create_role ? 1 : 0
  name  = var.existing_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

# Fetch existing IAM role if not creating
data "aws_iam_role" "existing" {
  count = var.create_role ? 0 : 1
  name  = var.existing_role_name
}

# Local variable for IAM role ARN
locals {
  role_arn = var.create_role ? aws_iam_role.lambda_role[0].arn : data.aws_iam_role.existing[0].arn
}

# IAM policy for Lambda S3 access
resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "${local.bucket_arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy only if creating role
resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  count      = var.create_role ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function
resource "aws_lambda_function" "api_to_s3" {
  function_name = "api-to-s3-lambda"
  runtime       = "java17"
  role          = local.role_arn
  handler       = "com.example.ApiToS3Handler::handleRequest"

  s3_bucket     = local.bucket_name
  s3_key        = "xmlfeed-1.0.0.jar"

  environment {
    variables = {
      BUCKET_NAME = local.bucket_name
      API_URL     = "https://api.example.com/data"
    }
  }

  memory_size = 512
  timeout     = 30
}

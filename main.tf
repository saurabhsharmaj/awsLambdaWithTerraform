provider "aws" {
  region = "us-east-1"
}

# S3 bucket
resource "aws_s3_bucket" "api_bucket" {
  bucket = "my-lambda-code-bucket-xml-feed"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_role"

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

# IAM policy for S3 access & logging
resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "${aws_s3_bucket.api_bucket.arn}/*"
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

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function
resource "aws_lambda_function" "api_to_s3" {
  function_name = "api-to-s3-lambda"
  runtime       = "java17"
  role          = aws_iam_role.lambda_role.arn
  handler       = "com.example.ApiToS3Handler::handleRequest"

  s3_bucket     = "my-lambda-code-bucket-xml-feed"
  s3_key        = "xmlfeed-1.0.0.jar"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.api_bucket.bucket
      API_URL     = "https://api.example.com/data"
    }
  }

  memory_size = 512
  timeout     = 30
}

# Lambda invocation example (manual trigger)
resource "aws_lambda_invocation" "test" {
  function_name = aws_lambda_function.api_to_s3.function_name
  input         = "{}"
}

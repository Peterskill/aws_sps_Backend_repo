resource "aws_dynamodb_table" "dynamotablecreation" {
  name = "aws_visitor_count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "user"

  attribute {
    name = "user"
    type = "S"
  }
  attribute {
    name="visitor_count"
    type = "N"
  }
}
resource "aws_iam_role" "auto-role" {
  name = "aws-lambda-role"
  assume_role_policy = jsondecode({

    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetRecords",
                "apigateway:GET",
                "apigateway:*"
            ],
            "Resource": "arn:aws:dynamodb:*:786862032690:table/*/stream/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:UpdateItem",
                "dynamodb:UpdateTable"
            ],
            "Resource": "arn:aws:dynamodb:*:786862032690:table/*"
        }
    ]

  })
}
data "archive_file" "zip-the-python-code" {
  type = "zip"
  source_file="lambda_function.py"
  output_path = "visitor_count.zip"
}
resource "aws_lambda_function" "awslambda" {
    filename = "visitor_count.zip"
    function_name = "aws-visitor_count"
    role=aws_iam_role.auto-role.arn
    handler = "lambda_handler"
    runtime = "python3.10"
    environment {
      variables = {
        TABLE_NAME = "aws_visitor_count"
      }
    }
}
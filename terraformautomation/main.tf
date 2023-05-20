resource "aws_dynamodb_table" "dynamotablecreation" {
  name = "aws_visitor_count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "user"

  attribute {
    name = "user"
    type = "S"
  }

}
resource "aws_iam_role" "auto-role" {
  name = "aws-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = "lambda-policy"
    policy=jsonencode({
    Version: 2012-10-17,
    Statement: [
        {
            Effect: "Allow",
            Action: "logs:CreateLogGroup",
            Resource: "arn:aws:logs:us-east-1:786862032690:*"
        },
        {
            Effect: "Allow",
            Action: [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            Resource: [
                "arn:aws:logs:us-east-1:786862032690:log-group:/aws/lambda/awsVistitorCount:*"
            ]
        }
    ]

  })
  }

}

resource "aws_iam_role_policy_attachment" "auto-role-policy2" {
  role= "aws-lambda-role"
  policy_arn = "arn:aws:iam::786862032690:policy/dynmolamda"
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
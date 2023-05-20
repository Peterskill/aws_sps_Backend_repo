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

}


resource "aws_iam_role_policy_attachment" "auto-role-policy1" {
  role = aws_iam_role.auto-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "auto-role-policy2" {
  role= aws_iam_role.auto-role.name
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
    handler = "app.lambda_handler"
    runtime = "python3.10"
    environment {
      variables = {
        TABLE_NAME = "aws_visitor_count"
      }
    }
}

resource "aws_apigatewayv2_api" "lambdaapi" {
  name = "aws-lambdaapigateway"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_headers = ["*"]
    allow_methods = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "lapistage" {
  api_id = aws_apigatewayv2_api.lambdaapi.id

  name = "$default"
  auto_deploy = true


}

resource "aws_apigatewayv2_integration" "laintegration" {
  api_id = aws_apigatewayv2_api.lambdaapi.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.awslambda.invoke_arn
}

resource "aws_apigatewayv2_route" "any" {
  api_id = aws_apigatewayv2_api.lambdaapi.id
  route_key = "$default"
  target = "integrations/${aws_apigatewayv2_integration.laintegration.id}"

}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.awslambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambdaapi.execution_arn}/*/*"
}
provider "aws" {
  region = var.aws_region
}


data "archive_file" "arquivo-lambda-pyvet" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function"
  output_path = "${path.root}/lambda_function.zip"
}

resource "aws_lambda_function" "lambda-pyvet" {
  function_name    = "lambda-pyvet-lambda"
  role             = aws_iam_role.role-lambda-pyvet.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.8"
  filename         = data.archive_file.arquivo-lambda-pyvet.output_path
  source_code_hash = data.archive_file.arquivo-lambda-pyvet.output_base64sha256
  provisioner "local-exec" {
    command = "pip install -r ${path.module}/lambda_function/requirements_dev.txt -t ${path.module}/lambda_function/"
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-pyvet.function_name
  principal     = "apigateway.amazonaws.com"
}


resource "aws_iam_role" "role-lambda-pyvet" {
  name = "role-lambda-pyvet"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "policy-lambda-pyvet" {
  name = "policy-lambda-pyvet"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role-policy-attachmet-pyvet" {
  policy_arn = aws_iam_policy.policy-lambda-pyvet.arn
  role       = aws_iam_role.role-lambda-pyvet.name
}

resource "aws_api_gateway_rest_api" "pyvet_api" {
  name = "pyvet-api"
}

resource "aws_api_gateway_resource" "pyvet-lambda-gtw-resource" {
  rest_api_id = aws_api_gateway_rest_api.pyvet_api.id
  parent_id   = aws_api_gateway_rest_api.pyvet_api.root_resource_id
  path_part   = "pyvet-lambda-function"
}

resource "aws_api_gateway_method" "pyvet_lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.pyvet_api.id
  resource_id   = aws_api_gateway_resource.pyvet-lambda-gtw-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pyvet_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.pyvet_api.id
  resource_id             = aws_api_gateway_resource.pyvet-lambda-gtw-resource.id
  http_method             = aws_api_gateway_method.pyvet_lambda_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda-pyvet.invoke_arn
}

resource "aws_api_gateway_deployment" "pyvet_api_deployment" {
  depends_on  = [aws_api_gateway_integration.pyvet_lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.pyvet_api.id
  stage_name  = "dev"
}


data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/authorizer_lambda"
  output_path = "${path.root}/authorizer_lambda.zip"
}

resource "aws_lambda_function" "authorizer_lambda" {
  function_name    = "pyvet-authorizer-lambda"
  role             = aws_iam_role.authorizer_role.arn
  handler          = "app.lambda_handler"
  runtime          = "python3.8"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  provisioner "local-exec" {
    command = "pip install -r ${path.module}/authorizer_lambda/requirements_dev.txt -t ${path.module}/authorizer_lambda/"
  }
}

resource "aws_api_gateway_authorizer" "pyvet_api_authorizer" {
  name            = "pyvet-api-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.pyvet_api.id
  type            = "TOKEN"
  identity_source = "method.request.header.Authorization"
  authorizer_uri  = aws_lambda_function.authorizer_lambda.invoke_arn
}

resource "aws_iam_role" "authorizer_role" {
  name = "pyvet-authorizer-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "authorizer_policy" {
  name = "pyvet-authorizer-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${var.aws_account_id}:${aws_api_gateway_rest_api.pyvet_api.id}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "authorizer_role_policy_attachment" {
  policy_arn = aws_iam_policy.authorizer_policy.arn
  role       = aws_iam_role.authorizer_role.name
}


resource "aws_api_gateway_method_settings" "example" {
  rest_api_id = aws_api_gateway_rest_api.pyvet_api.id
  stage_name = "dev"
  method_path = "${aws_api_gateway_resource.pyvet-lambda-gtw-resource.path_part}/${aws_api_gateway_method.pyvet_lambda_method.http_method}"
  settings {
    throttling_burst_limit = 500
    throttling_rate_limit = 1000
  }
}
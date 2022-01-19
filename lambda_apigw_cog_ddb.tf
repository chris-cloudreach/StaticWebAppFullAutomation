# COGNITO
resource "aws_cognito_user_pool" "pool" {
  name = "WildRydes"
  auto_verified_attributes = ["email"]
  
}

resource "aws_cognito_user_pool_client" "client" {
  name = "WildRydesWebApp"
  explicit_auth_flows = ["USER_PASSWORD_AUTH"]

  user_pool_id = aws_cognito_user_pool.pool.id
}

# DYNAMODB
resource "aws_dynamodb_table" "UnicornRides-ddb-table" {
  name           = var.ddb_table_name
  billing_mode   = var.Billing_mode
  read_capacity  = 5
  write_capacity = 5
  hash_key       = var.partition_key
#   range_key      = "GameTitle" This is the sort key

  attribute {
    name = var.partition_key
    type = "S"
  }

  tags = {
    Name        = "UnicornRides"
    Environment = "production"
  }
}


#REST API for the Lambda
resource "aws_api_gateway_rest_api" "wildrydes" {
  name = "WildRydes"
  description = "API Gateway for Cognito"
}
#API Gateway Authoriser for Cognito
resource "aws_api_gateway_authorizer" "WildRydes" {
  name                   = "WildRydes"
  type                   = "COGNITO_USER_POOLS"
  provider_arns          =  [aws_cognito_user_pool.pool.arn]
  rest_api_id            = aws_api_gateway_rest_api.wildrydes.id
  depends_on = [
    aws_cognito_user_pool.pool
  ]
}
#API Gateway Resource for API
resource "aws_api_gateway_resource" "ride" {
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  parent_id   = aws_api_gateway_rest_api.wildrydes.root_resource_id
  path_part   = "ride"
}
#Gateway Method for API
resource "aws_api_gateway_method" "cors_method" {
  rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
  resource_id   = aws_api_gateway_resource.ride.id
  http_method   = "OPTIONS"
  authorization = "NONE"

}

#Gateway Integration
resource "aws_api_gateway_integration" "cors_integration" {
  http_method = aws_api_gateway_method.cors_method.http_method
  resource_id = aws_api_gateway_resource.ride.id
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  #integration_http_method = "POST"
  type = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" : "{\"statusCode\": 200}"
  }
}
#Gateway Integration Response
resource "aws_api_gateway_integration_response" "cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  resource_id = aws_api_gateway_resource.ride.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = aws_api_gateway_method_response.cors_method_response.status_code



    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
      depends_on = [aws_api_gateway_method_response.cors_method_response]


}

#Gateway Method Response
resource "aws_api_gateway_method_response" "cors_method_response" {
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  resource_id = aws_api_gateway_resource.ride.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = 200

    response_parameters =  {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true
    }

}

#addition
resource "aws_api_gateway_method" "lambda_method" {
    rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
    resource_id   = aws_api_gateway_resource.ride.id
    http_method   = "POST"
    authorization = "COGNITO_USER_POOLS"
    authorizer_id = aws_api_gateway_authorizer.WildRydes.id
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
    rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
    resource_id   = aws_api_gateway_resource.ride.id
    http_method   = aws_api_gateway_method.lambda_method.http_method
    status_code   = "200"
    response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true,

  }

  depends_on = [aws_api_gateway_method.cors_method]



}

resource "aws_api_gateway_integration" "integration" {
    rest_api_id   = aws_api_gateway_rest_api.wildrydes.id
    resource_id   = aws_api_gateway_resource.ride.id
    http_method   = aws_api_gateway_method.lambda_method.http_method
    integration_http_method = "POST"
    type          = "AWS_PROXY"
    uri           = aws_lambda_function.lambdaNew.invoke_arn

}


#Gateway Deployment for API
resource "aws_api_gateway_deployment" "ride_deployment" {
  rest_api_id = aws_api_gateway_rest_api.wildrydes.id
  stage_name  = "DEV"
  depends_on    = [aws_api_gateway_integration.integration]
  lifecycle {
    create_before_destroy = true
  }

}
resource "aws_api_gateway_account" "logs_for_api" {
  cloudwatch_role_arn = "${aws_iam_role.cloudwatch.arn}"
}

# resource "aws_api_gateway_method_settings" "wildrydes_settings" {
#   rest_api_id = aws_api_gateway_rest_api.wildrydes.id
#   stage_name  = DEV
#   method_path = "*/*"
#   settings {
#     logging_level = "INFO"
#     data_trace_enabled = true
#     metrics_enabled = true
#   }
# }

resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}



resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = "${aws_iam_role.cloudwatch.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda_role" {
  name               = "iam_role_lambda_function"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# IAM policy for logging from a lambda and access to S3

resource "aws_iam_policy" "lambda_logging" {

  name        = "iam_policy_lambda_1"
  path        = "/"
  description = "IAM policy for new lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Sid" : "SpecificTable",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchGet*",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTable",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWrite*",
          "dynamodb:CreateTable",
          "dynamodb:Delete*",
          "dynamodb:Update*",
          "dynamodb:PutItem"
        ],
        "Resource" : "arn:aws:dynamodb:*:*:table/Rides"
      }
    ]
  })
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

#creation of lambda function
data "archive_file" "image_script" {
  type        = "zip"
  source_file = "${path.module}/files/${var.script_filename}.js"  # SOURCE OF THE FILE
  output_path = "${path.module}/files/${var.script_filename}.zip" # DESTINATION OF THE GENERATED FILE (.zip)
}


resource "aws_lambda_function" "lambdaNew" {
  filename         = data.archive_file.image_script.output_path
  function_name    = var.script_filename
  handler          = "${var.script_filename}.handler"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs14.x"
  source_code_hash = data.archive_file.image_script.output_base64sha256

}

resource "aws_lambda_permission" "allowapi" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = "lambdaRide"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.wildrydes.execution_arn}/*/*/*"
}
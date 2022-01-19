
output "userPoolClientId" {
 value = aws_cognito_user_pool_client.client.id
}

output "userPoolId" {
 value = aws_cognito_user_pool.pool.id
}

# output "UserpoolArn" {
#  value = aws_cognito_user_pool.pool.arn
# }

output "invokeUrl" {
  description = "Deployment invoke url"
  value       = aws_api_gateway_deployment.ride_deployment.invoke_url
}

# output "UnicornRides_ARN" {
#  value = aws_dynamodb_table.UnicornRides-ddb-table.arn
# }

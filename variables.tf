
variable "script_filename" {
  description = "The file name of script"
}

# variable "cognito_user_arn" {
#   description = "Cognito User ARN"
#   type        = string
# }


variable "ddb_table_name" {
  description = "The name of the dynamodb table"
  type        = string
}

variable "partition_key" {
  description = "Partition key name of the dynamodb table"
  type        = string
}

variable "Billing_mode" {
  description = "Table billing mode"
  type        = string
}

variable "Region" {
  description = "Deployment region"
  type        = string
}


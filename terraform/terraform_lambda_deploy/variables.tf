variable "region" {
  type    = string
}

variable "account_id" {
  type    = string
}

variable "lambda_function_name" {
   default  = "saas-mysql-lambda"
}

variable "lambda_runtime" {
   default = "python3.7"
}

variale "lambda_build_packages" {
   default = "saas_mysql_python_packages"
}

variable "lambda_handler" {
   type     = string
   default  = "lambda_handler"
}

variable "lambda_role_name" {
   type    = string
   default = "lambda-mysql"
}

variable "lambda_timeout" {
   default = 120
}

variable "lambda_file_name" {
   type    = string
   default = "lambda_function_payload.zip"
}

variable "lambda_memory_size" {
  type    = string
  default = 128
}

variable "lambda_vpc_security_group_id" {
   type = string
}

variable "lambda_vpc_subnet_id" {
   type  = string
}

variable "log_file" {
   type = string
}

variable "s3_bucket" {
   type = string
}

variable "secret_name" {
   type = string
}

variable "sql_cmd" {
   type = string
}






provider "aws" {
  version             = "2.57"
  region              = var.region
  allowed_account_ids = [var.account_id]
}

data "template_file" "lambda_iam_policy" {
  template = file("${path.module}/data/iam_policy.tpl")
  vars = {
    "account_id"            = var.account_id
    "lambda_function_name"  = var.lambda_function_name
    "region"                = var.region
  }
}

data "template_file" "lambda_python_script" {
  template = file("${path.module}/data/mysql-lambda_py.tpl")
}

resource "local_file" "lambda_python_script" {
  content  = data.template_file.lambda_python_script.rendered
  filename = "${var.lambda_build_packages}/mysql-lambda.py"
}

data "archive_file" "lambda_zip_package" {
   type        = "zip"
   output_path = "${path.module}/${var.lambda_file_name}"

   source_dir  = var.lambda_build_packages 

   depends_on  =  [
      local_file.lambda_python_script
   ]   
}

resource "aws_iam_role" "lambda_exec_role" {
   name               = join("-", [var.lambda_role_name, "role"])
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

resource "aws_iam_policy" "lambda_role_policy" {
   name    = join("-", [var.lambda_function_name, "lambda-exec-role-policy"])
   policy  = data.template_file.lambda_iam_policy.rendered
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_role_policy.arn
}

resource "aws_lambda_function" "saas_lambda" {
  filename              = data.archive_file.lambda_zip_package.output_path
  function_name         = var.lambda_function_name
  role                  = aws_iam_role.lambda_exec_role.arn
  handler               = join(".", ["mysql-lambda", var.lambda_handler])
  timeout               = var.lambda_timeout
  source_code_hash      = data.archive_file.lambda_zip_package.output_base64sha256
  memory_size           = var.lambda_memory_size

  vpc_config {
    security_group_ids  = [var.lambda_vpc_security_group_id]
    subnet_ids          = [var.lambda_vpc_subnet_id]
  }

  runtime               = var.lambda_runtime

  environment {
     variables = {
      LOG_FILE    = var.log_file
      REGION      = var.region
      S3_BUCKET   = var.s3_bucket
      SECRET_NAME = var.secret_name
      SQL_CMD     = var.sql_cmd 
     }
  }
}

provider "aws" {
  version   = "~> 2.0"
  region    = "${var.region}"
}

variable "github_token" {
   type    = "string"
   default = "b8c2009813e6429575db8cfdcf7b61bf2216d9aa"
}

variable "repo_owner" {
   type    = "string"
   default = "nedema"
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "s3bucket" {
  type        = string
  default     = "helloworld-react-bucket"
}

variable "gitrepo" {
   type    = "string"
   default = "reactapp"
}

variable "vpcidr" {
   type    = "string"
   default = "10.10.0.0/16"
}

variable "keypair" {
   type    = "string"
   default = "~/.ssh/id_rsa.pub"
}
variable "cidrsubnet" {
   type    = "string"
   default = "10.10.0.0/24" 
}

variable "elastic_beanstalk_application_name" {
   type    = "string"
   default = "react_app"
}

variable "elastic_beanstalk_environment_name" {
   type    = "string"
   default = "react_app_env" 
}


resource "aws_vpc" "main" {
   cidr_block  = "${var.vpcidr}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}


resource "aws_subnet" "public" {
    vpc_id                  = "${aws_vpc.main.id}"
    cidr_block              = "${var.cidrsubnet}"
    availability_zone       = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_key_pair" "key" {
   key_name   = "key"
   public_key = "${file(var.keypair)}"
}

resource "aws_s3_bucket" "pipeline_bucket" {
  bucket = "${var.s3bucket}"
  acl    = "private"
  region = "${var.region}"
}

resource "aws_iam_role" "pipeline_role" {
  name = "pipeline-role"

  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": {
            "Service": "codepipeline.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
      }
   ]
}
   EOF
}

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.pipeline_role.id}"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": [
            "s3:CreateBucket",
            "s3:GetAccelerateConfiguration",
            "s3:GetBucketAcl",
            "s3:GetBucketCORS",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObject"
         ],
         "Resource": [
            "${aws_s3_bucket.pipeline_bucket.arn}",
            "${aws_s3_bucket.pipeline_bucket.arn}/*"
         ]
      },
      {
         "Effect": "Allow",
         "Action": [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
         ],
         "Resource": "*"
      }
   ]
}
   EOF
}

resource "aws_iam_role_policy" "pipeline-bucket-access" {
  name = "code-pipeline-bucket-access"
  role = "${aws_iam_role.pipeline_role.id}"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Resource": [
            "${aws_s3_bucket.pipeline_bucket.arn}",
            "${aws_s3_bucket.pipeline_bucket.arn}/*"
         ],
         "Action": [
            "s3:CreateBucket",
            "s3:GetAccelerateConfiguration",
            "s3:GetBucketAcl",
            "s3:GetBucketCORS",
            "s3:GetBucketLocation",
            "s3:GetBucketLogging",
            "s3:GetBucketNotification",
            "s3:GetBucketPolicy",
            "s3:GetBucketRequestPayment",
            "s3:GetBucketTagging",
            "s3:GetBucketVersioning",
            "s3:GetBucketWebsite",
            "s3:GetLifecycleConfiguration",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:GetObjectTagging",
            "s3:GetObjectTorrent",
            "s3:GetObjectVersion",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectVersionTorrent",
            "s3:GetReplicationConfiguration",
            "s3:ListAllMyBuckets",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:ListBucketVersions",
            "s3:ListMultipartUploadParts",
            "s3:PutObject"
         ]
      }
   ]
}
EOF
}

resource "aws_security_group" "sg_rules" {
  name              = "allow_rules"
  vpc_id            = "${aws_vpc.main.id}"

   ingress {
      from_port         = 22
      to_port           = 22
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
   }

   ingress {
      from_port         = 8000
      to_port           = 8000
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
   }

   ingress {
      from_port         = 80
      to_port           = 80
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
   }

   egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_codebuild_project" "cicd_project" {
   name          = "cicd-project"
   description   = "test_cicd_codebuild_project"
   build_timeout = "5"
   service_role  = "${aws_iam_role.pipeline_role.arn}"

   artifacts {
      type = "CODEPIPELINE"
   }

   environment {
      compute_type                = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/standard:1.0"
      type                        = "LINUX_CONTAINER"
      image_pull_credentials_type = "CODEBUILD"
   }

   source {
      type = "CODEPIPELINE"
   }

   logs_config {
      cloudwatch_logs {
         group_name = "log-group"
         stream_name = "log-stream"
      }

      s3_logs {
         status = "ENABLED"
         location = "${aws_s3_bucket.pipeline_bucket.id}/build-log"
      }
   }

   // source {
   //    type            = "GITHUB"
   //    location        = "${var.gitrepo}"
   //    git_clone_depth = 1
   // }

   vpc_config {
      vpc_id = "${aws_vpc.main.id}"

      subnets = [
         "${aws_subnet.public.id}",
      ]

      security_group_ids = [
         "${aws_security_group.sg_rules.id}",
      ]
   }
}

resource "aws_codepipeline" "default" {
  name     = "react_cicd_pipeline"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.pipeline_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        OAuthToken           = "${var.github_token}"
        Owner                = "${var.repo_owner}"
        Repo                 = "${var.gitrepo}"
        Branch               = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "cicd_reactjs"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
         name            = "Deploy"
         category        = "Deploy"
         owner           = "AWS"
         provider        = "ElasticBeanstalk"
         input_artifacts = ["build_output"]
         version         = "1"

         configuration = {
            ApplicationName = "${var.elastic_beanstalk_application_name}"
            EnvironmentName = "${var.elastic_beanstalk_environment_name}"
         }
      }
   }
  }
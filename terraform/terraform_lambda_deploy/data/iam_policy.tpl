{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": [
               "s3:GetAccessPointPolicyForObjectLambda",
               "s3:GetBucketLogging",
               "s3:CreateBucket",
               "s3:GetBucketPolicy",
               "s3:GetBucketPolicyStatus",
               "s3:GetBucketLocation",
               "s3:GetAccessPointForObjectLambda",
               "s3:PutObject",
               "s3:GetObjectAcl",
               "s3:GetObject",
               "s3:ListAccessPointsForObjectLambda",
               "s3:GetAccessPoint",
               "secretsmanager:GetSecretValue",
               "s3:GetAccountPublicAccessBlock",
               "s3:ListAccessPoints",
               "logs:CreateLogGroup",
               "logs:CreateLogStream",
               "logs:PutLogEvents",
               "ec2:DescribeInstances",
               "ec2:CreateNetworkInterface",
               "ec2:DeleteNetworkInterface",
               "ec2:DescribeNetworkInterfaces",
               "ec2:AttachNetworkInterface"
           ],
           "Resource": "*"
       }
   ]
}


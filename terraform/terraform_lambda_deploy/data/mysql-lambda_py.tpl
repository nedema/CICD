import sys
import base64
import os
import datetime
import re
import csv

import json
import logging
import pymysql
import boto3

from botocore.exceptions import ClientError
from json import JSONEncoder
from prettytable import from_db_cursor


SECRET_NAME = os.environ['SECRET_NAME']
SQL_CMD = os.environ['SQL_CMD']
REGION = os.environ['REGION']
S3_BUCKET = os.environ['S3_BUCKET']
LOGFILE = os.environ['LOG_FILE']

match = ['select', 'SELECT']

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
   session = boto3.session.Session()
   s3 = boto3.client('s3')
   s3.create_bucket(Bucket=S3_BUCKET)
   client = session.client(
      service_name='secretsmanager',
      region_name=REGION
   )
   try:
      get_secret_value_response = client.get_secret_value(SecretId=SECRET_NAME)
   except ClientError as e:
      raise e
   else:
      if 'SecretString' in get_secret_value_response:
          secret = get_secret_value_response['SecretString']
      else:
          secret = base64.b64decode(get_secret_value_response['SecretBinary'])
         
   resp = json.loads(secret)
   db_user = resp['username']
   db_instance_id = resp['dbInstanceIdentifier']
   password = resp['password']
   rds_host = resp['host']
   db_name = resp['dbname']
   cmd = SQL_CMD.split(';')[:-1]
   
   file_name = LOGFILE + '-logs.txt'
   file_name_csv = LOGFILE + '-logs.csv'
   lambda_path = "/tmp/" + file_name
   
   try:
      conn = pymysql.connect(host=rds_host, user=db_user, passwd=password, db=db_name, connect_timeout=20)
   except pymysql.MySQLError as e:
      logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
      sys.exit()
      
   logger.info("SUCCESS: Connection to RDS MySQL instance succeeded") 
   
   original_stdout = sys.stdout
   pattern_match = (re.findall(r"(?=("+'|'.join(match)+r"))", SQL_CMD))
   if pattern_match:
      with conn:
         cursor = conn.cursor()
         for x in cmd:
            print(cmd)
            with open(lambda_path, 'a') as data:
               sys.stdout = data
               cursor.execute(x + ';')
               resp = from_db_cursor(cursor)
               results = cursor.fetchall()
               csv_writer = csv.writer(data)
               csv_writer.writerows(results)
               print(resp)
               sys.stdout = original_stdout
               print(resp)
            response = s3.upload_file(lambda_path, S3_BUCKET, file_name)
            response = s3.upload_file(lambda_path, S3_BUCKET, file_name_csv)
   else:
      logger.error("Prohibited SQL statement used.")
      sys.exit()

   return

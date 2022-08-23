import os
import json
import random

import pulumi
from pulumi import export
from pulumi_aws import s3

stack = pulumi.get_stack()
print('stack', stack)

config = pulumi.Config()
data = config.require_object('data')
print('data', data)

def public_read_policy(bucket):
  return json.dumps({
    'Version': '2012-10-17',
    'Statement': [{
      'Effect': 'Allow',
      'Principal': '*',
      'Action': [
        's3:GetObject'
      ],
      'Resource': [
        f'arn:aws:s3:::{bucket}/*',
      ]
    }]
  })

if 'active' in data and data['active'] == 'true':
  generated_bucket_name = 's3-bucket-%016x' % random.randrange(16 ** 16)
  bucket_name = data['bucket_name'] if 'bucket_name' in data else generated_bucket_name
  print('bucket_name', bucket_name)

  custom_bucket = s3.Bucket(bucket_name)

  bucket_id = custom_bucket.id
  bucket_policy = s3.BucketPolicy('bucket-policy',
                                  bucket=bucket_id,
                                  policy=bucket_id.apply(public_read_policy))

  export('bucket_id', custom_bucket.id)

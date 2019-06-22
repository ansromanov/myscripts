import boto3
import os
 
def upload_files(path, bucket_name):
    session = boto3.Session(
        # aws_access_key_id='YOUR_AWS_ACCESS_KEY_ID',
        # aws_secret_access_key='YOUR_AWS_SECRET_ACCESS_KEY_ID',
        # region_name='YOUR_AWS_ACCOUNT_REGION'
    )
    s3 = session.resource('s3')
    bucket = s3.Bucket(bucket_name)
 
    for subdir, dirs, files in os.walk(path):
        for file in files:
            full_path = os.path.join(subdir, file)
            with open(full_path, 'rb') as data:
                bucket.put_object(Key=full_path[len(path)+1:], Body=data)
 
if __name__ == "__main__":
    path = '/Users/aromanov/Desktop/s3/steelrain'
    bucket = 'steelrain-articles'
    upload_files(path, bucket)
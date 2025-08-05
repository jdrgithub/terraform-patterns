import boto3
import os
import logging
from urllib.parse import unquote_plus
from botocore.exceptions import ClientError

# Set up structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create the S3 client
s3 = boto3.client("s3")

def lambda_handler(event, context):
  try:
    # Basic metadata
    # Get bucket name from first record
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    # Extracts the S3 object key (filename) from the event that triggered the Lambda
    # Then decodes from URL encoding it is passed with
    key_triggered = unquote_plus(event['Records'][0]['s3']['object']['key'])

    # Gets input and output prefixes
    input_prefix = os.environ.get("INPUT_PREFIX", "")
    output_prefix = os.environ.get("OUTPUT_PREFIX", "processed/")

    logger.info(f"Lambda triggered by: {bucket_name}/{key_triggered}")
    logger.info(f"Scanning prefix: {input_prefix} -> output will go to: {output_prefix}")

    # Use the S3 paginator to list objects in bucket with prefix
    paginator = s3.get_paginator('list_object_v2')
    pages = paginator.paginate(Bucket=bucket_name, Prefix=input_prefix)
    
    # Initializes counters and list for failed files
    processed_count = 0
    skipped_count = 0
    failed_files = []
    
    '''
    # LOOKS LIKE THIS 
    page = {
    'Contents': [
        {'Key': 'input/data1.txt', 'LastModified': '2023-08-01T12:00:00Z', 'Size': 1234},
    '''

    for page in pages:
      for obj in page.get('Contents', []):
        key = obj['Key']

        # Skip already-processed or invalid files
        if key.endswith('/') or key.startswith(output_prefix) or key.endswith('-processed.txt'):
          skipped_count += 1
          continue
        
        logger.info(f"Processing: {key}")
        try:
          # Get file content
          response = s3.get_object(Bucket=bucket_name, Key=key)
          body_bytes = response['Body'].read()
          
          try:
            body = body_bytes.decode('utf-8')
          except:
            logger.warning(f"Skipping binary or non-UTF-8 file: {key}")
            skipped_count += 1
            continue

          # Process logic
          new_body = body + "\nProcessed by Lambda."

          # Create new key
          filename = key.split('/')[-1]  # take just the filename without prefix
          new_key = f"{output_prefix}{filename.replace('.txt', '')}-processed.txt" # replace .txt with -processed.txt
          
          # Write back
          s3.put_object(Bucket=bucket_name, Key=new_key, Body=new_body.encode('utf-8'))
          logger.info(f"Wrote: {new_key}") 
          processed_count += 1
          
        except ClientError as s3_err:
          logger.error(f"Failed to process {key}: {s3_err}")
          failed_files.append(key)
    
    logger.info(f"Lambda run complete: {processed_count} processed, {skipped_count} skipped, {len(failed_files)} failed ")
    if failed_files:
      logger.warning(f"Failed files: {failed_files}")

  except Exception as e:
    logger.exception("Unhandled error in Lambda handler")
    raise # Let AWS see the failure for retry or alerting
          


    
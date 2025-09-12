#!/bin/bash

# Output file
output_file="s3_bucket_acl_status.txt"
> "$output_file"

# Get list of all S3 buckets
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

# Loop through each bucket and get ownership controls
for bucket in $buckets; do
  echo "Bucket: $bucket" >> "$output_file"
  result=$(aws s3api get-bucket-ownership-controls --bucket "$bucket" 2>&1)

  if echo "$result" | grep -q "OwnershipControlsNotFoundError"; then
    echo "ACL Status: ACLs Enabled" >> "$output_file"
  elif echo "$result" | grep -q "\"ObjectOwnership\": \"BucketOwnerEnforced\""; then
    echo "ACL Status: ACLs Disabled" >> "$output_file"
  else
    echo "ACL Status: ACLs Enabled (OwnershipControls present but not enforced)" >> "$output_file"
  fi

  echo "" >> "$output_file"
done


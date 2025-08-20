#!/bin/bash

log_dir = "/var/log/app"
archived_dir = "/var/log/app/archieve"

mkdir -p $archived_dir

# will filter the files which were modified last 2 days ago
for file in $(find $log_dir -name "*.log" -mtime +2)
do
  gzip "$file" && mv "$file.gz" "$archived_dir"
done

# will find & delete the old files which are modified before 30 days
find $archived_dir -mtime +30 -delete

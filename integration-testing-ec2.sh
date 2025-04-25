#!/bin/bash

echo "Integration Testing..."
aws --version

# Get EC2 instances data
Data=$(aws ec2 describe-instances)

# Extract the Public DNS of the instance with the "dev-deploy" tag
URL=$(echo "$Data" | jq -r '.Reservations[].Instances[] | select(.Tags[].Value == "pipeline-dev-deploy") | .PublicDnsName')
echo "URL - $URL"

# Check if URL was found
if [[ -n "$URL" ]]; then
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:80)
  echo "HTTP Code - $http_code"
else
  echo "Could not fetch a token/URL"
  exit 1
fi


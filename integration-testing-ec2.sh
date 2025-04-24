echo "Integration Testing..."
aws --version

Data=$(aws ec2 describe-instances)
echo "Data - "$Data
URL=$(aws ec2 describe-instances | jq -r ' .Reservations[].Instances[] | select(.Tags[].Value == "dev-deploy") | .PublicDnsName')
echo "URL -"$URL

if [[ "$URL" != '' ]]; then
  http_code=$(curl -s -o /dev/null -w "%{http_code}" http://$URL:80)
    echo "http_code -"$http_code
else
  echo "Could not fetch a token/URL"
  exit 1;

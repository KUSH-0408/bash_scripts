#!/bin/bash
##################################################
## Purpose: Monitor SSL certificate expiry & alert via xMatters
##################################################

# Configurable variables
cert_folder="certificates"
confluence_page_link="https://confluence.mastercard.int/pages/viewpage.action?pageId=945865844"
xmatters_user="finicity_user"
xmatters_pass="$xmatters_pass"
xmatters_url="https://mastercard.hosted.xmatters.com/reapi/2015-04-01/forms/9632341a-4a90-45b1-91cf-fb6bc127632d/triggers"
#xmatters_url="https://mastercard-np.hosted.xmatters.com/reapi/2015-04-01/forms/d3e73cf2-1408-4eea-a5af-96262221f894/triggers"
recipient="OFin_Cloud_Operations"

# Thresholds
warning_thresholds=(120 90 60)
critical_threshold=30
current_date=$(date +%s)

for cert_file in "$cert_folder"/*; do
    # Validate certificate
    if ! openssl x509 -in "$cert_file" -noout -subject -dates >/dev/null 2>&1; then
        echo "Error: $cert_file is not a valid certificate file. Skipping."
        continue
    fi

    # Extract certificate details
    common_name=$(openssl x509 -in "$cert_file" -noout -subject | awk -F '=' '/CN/ {print $NF}')
    cert_expiry_date=$(openssl x509 -noout -enddate -in "$cert_file" | cut -d= -f2)
    expiration_date=$(date -d "$cert_expiry_date" +%s)
    days_until_expiration=$(( (expiration_date - current_date) / 86400 ))
    serial_number=$(openssl x509 -in "$cert_file" -noout -serial | cut -d= -f2)
    md5_checksum=$(openssl x509 -noout -modulus -in "$cert_file" | openssl md5 | awk '{print $2}')

    # Determine severity
    severity="LOW"
    if [ "$days_until_expiration" -le "$critical_threshold" ]; then
        severity="HIGH"
    elif [[ " ${warning_thresholds[@]} " =~ " ${days_until_expiration} " ]]; then
        severity="MEDIUM"
    else
        continue
    fi

    # Compose message
    message="Certificate Expiry Alert - CN: ${common_name}, Serial: ${serial_number}"
    summary="Certificate File: ${cert_file}\nCommon Name: ${common_name}\nSerial Number: ${serial_number}\nMD5 Checksum: ${md5_checksum}\nExpiry Date: ${cert_expiry_date}\nDays Until Expiration: ${days_until_expiration}\nRunbook: ${confluence_page_link}"

    # Send to xMatters
    curl -X POST "$xmatters_url" \
        -u "$xmatters_user:$xmatters_pass" \
        -H "Content-Type: application/json" \
        -d '{
            "recipients": [
                {
                    "targetName": "'"${recipient}"'"
                }
            ],
            "priority": "'"${severity}"'",
            "properties": {
                "common_name": "'"${common_name}"'",
                "serial_number": "'"${serial_number}"'",
                "md5_checksum": "'"${md5_checksum}"'",
                "cert_file": "'"${cert_file}"'",
                "days_until_expiration": "'"${days_until_expiration}"'",
                "cert_expiry_date": "'"${cert_expiry_date}"'",
                "confluence_page_link": "'"${confluence_page_link}"'",
                "message": "'"${message}"'",
                "summary": "'"${summary}"'"
            }
        }'
    # Teams webhook URL
    #webhook_url="$webhook"

    # Send to Teams using curl
    curl -X POST "$webhook_url" \
    -H "Content-Type: application/json" \
    -d "{
        \"text\": \"**$message**\n\n$summary\"
        }"
done

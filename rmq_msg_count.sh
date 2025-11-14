#!/bin/bash
source /etc/environment

usage() {
  echo -e "Usage: $0
      -q <QUEUE_NAME> \tSelect Queue name. List the queue name, if required (Mandatory)
      -l all   \tTo list all queues except mfa queues (Optional)
      -p       \tTo set buffer in percent. Use value like 0.1 for 10% (Optional)
      -I <int> \tTo set ideal value threshold for message ready count
      -h <help>\tDisplays this help message

 Example Usage: $0 -q cclite -I 2000000" 1>&2
  exit 3
}

while getopts "q:l:p:h:I:" option; do
  case "${option}" in
    q) QUEUE_NAME=${OPTARG};;
    l) LIST=1;;
    I) IDEAL_VALUE=${OPTARG};;
    p) BUFF_PER=${OPTARG};;
    h) usage;;
    *) usage;;
  esac
done

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

if [ -z "${QUEUE_NAME}" ]; then
  echo "No Queue Name Found"
  usage
  exit 1
else
  echo "Queue Selected: $QUEUE_NAME" > /dev/null
fi

if [ -z "${IDEAL_VALUE}" ]; then
  echo "No Ideal Value Set"
  usage
  exit 1
else
  echo "Ideal Value: $IDEAL_VALUE" > /dev/null
fi

if [ -z "${BUFF_PER}" ]; then
  echo "Using Default Buffer of 0.1"
  BUFF_PER=0.1
else
  echo "Buffer Percent: $BUFF_PER" > /dev/null
fi

TEN_PER_VALUE=$(awk -vn=$IDEAL_VALUE -vp=$BUFF_PER 'BEGIN{print(n*p)}')
MAX_COUNT=$(expr $IDEAL_VALUE + $TEN_PER_VALUE)
MIN_COUNT=$(expr $IDEAL_VALUE - $TEN_PER_VALUE)

QUEUE_STATS=$(curl --silent -k -u "daily-batch-monitor-script:ahv6yohN$&*Ii8Theem" https://rmqcluster.prod.fini.city:15672/api/queues/%2F/$QUEUE_NAME | jq -r '.')
READY_MESSAGE_COUNT=$(echo "$QUEUE_STATS" | jq -r '.messages_ready')
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

if [[ $READY_MESSAGE_COUNT == null || $READY_MESSAGE_COUNT == 0 ]]; then
  echo "$TIMESTAMP Error While Fetching Data. Please check - $QUEUE_STATS" >> /tmp/logfile_cronscript
  exit 0
fi

if (( $(echo "$READY_MESSAGE_COUNT > $MAX_COUNT" | bc -l) )); then
  echo "$TIMESTAMP Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT Which Is More Than Threshold Of $MAX_COUNT" >> /tmp/logfile_cronscript

  curl -X POST https://mastercard.hosted.xmatters.com/reapi/2015-04-01/forms/e424c012-8738-44c2-aef4-70c13bec6e78/triggers -u finicity_user:Api@fc3254 \
    -H 'Content-Type: application/json' \
    -d "{
      \"recipients\": [
        {
          \"targetName\": \"OFin_Cloud_Operations\"
        }
      ],
      \"priority\": \"LOW\",
      \"properties\": {
        \"confluence_page_link\": \"https://confluence.mastercard.int/spaces/TEC/pages/945871009/Runbook+Scenario+-+Batch+Alerts\",
        \"message\": \"Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT Which Is More Than Threshold Of $MIN_COUNT\",
        \"summary\": \"CRITICAL - Queue $QUEUE_NAME with More message count\"
      }
    }"

  curl -X POST "https://mastercard.webhook.office.com/webhookb2/b2fe4227-a5cb-4fdf-8246-e4b924986b6b@f06fa858-824b-4a85-aacb-f372cfdc282e/IncomingWebhook/51852c59c4434a9e8381ed14ed84cd04/864e8001-af85-447a-8c60-486b6ddece6f/V2_9PYIDuKrOopgLkeGkBpTWw2_FfAKQON2J_0q9CquVQ1" \
    -H "Content-Type: application/json" \
    -d "{
      \"text\": \"Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT Which Is More Than Threshold Of $MAX_COUNT\nCRITICAL - Queue $QUEUE_NAME with More message count\nRunbook : https://confluence.mastercard.int/spaces/TEC/pages/945871009/Runbook+Scenario+-+Batch+Alerts\"
    }"

elif (( $(echo "$READY_MESSAGE_COUNT < $MIN_COUNT" | bc -l) )); then
  echo "$TIMESTAMP Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT Which Is Less Than Threshold Of $MIN_COUNT" >> /tmp/logfile_cronscript

  curl -X POST https://mastercard.hosted.xmatters.com/reapi/2015-04-01/forms/e424c012-8738-44c2-aef4-70c13bec6e78/triggers -u finicity_user:Api@fc3254 \
    -H 'Content-Type: application/json' \
    -d "{
      \"recipients\": [
        {
          \"targetName\": \"OFin_Cloud_Operations\"
        }
      ],
      \"priority\": \"LOW\",
      \"properties\": {
        \"confluence_page_link\": \"https://confluence.mastercard.int/spaces/TEC/pages/945871009/Runbook+Scenario+-+Batch+Alerts\",
        \"message\": \"Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT Which Is Less Than Threshold Of $MIN_COUNT\",
        \"summary\": \"CRITICAL - Queue $QUEUE_NAME with less message count\"
      }
    }"

  curl -X POST "https://mastercard.webhook.office.com/webhookb2/b2fe4227-a5cb-4fdf-8246-e4b924986b6b@f06fa858-824b-4a85-aacb-f372cfdc282e/IncomingWebhook/51852c59c4434a9e8381ed14ed84cd04/864e8001-af85-447a-8c60-486b6ddece6f/V2_9PYIDuKrOopgLkeGkBpTWw2_FfAKQON2J_0q9CquVQ1" \
    -H "Content-Type: application/json" \
    -d "{
      \"text\": \"Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT Which Is Less Than Threshold Of $MIN_COUNT\nCRITICAL - Queue $QUEUE_NAME with less message count\nRunbook : https://confluence.mastercard.int/spaces/TEC/pages/945871009/Runbook+Scenario+-+Batch+Alerts\"  
    }"

else
  echo "$TIMESTAMP Message Ready Count For $QUEUE_NAME Is $READY_MESSAGE_COUNT which Is In The Range Of $MIN_COUNT And $MAX_COUNT" >> /tmp/logfile_cronscript
fi

#!/bin/bash
REGION=us-west-2 #replace region as per your requirement
echo "WARNING!!! Please note this script will delete all snapshots for the given Month & Phase, please enter details carefully."
sleep 5
echo "Please enter patching month"
read -r input
PATCHING_MONTH=$(echo "$input" | cut -c 1-3 | sed -e "s/\b./\u\0/g") #Trims user input to first 3 chars & converts first char to uppercase
PATCHING_CYCLE=$PATCHING_MONTH-*
echo "Please enter patching PHASE's number of which you want to delete snapshots i.e (1,2,3,..,etc.): "
read -r PHASE_NUMBER
if [ -n "$PHASE_NUMBER" ] && [ "$PHASE_NUMBER" -gt 0 ];then
{
echo "Are you deleting snapshots in same month? Type yes/no"
read -r VALUE
  if [ "$VALUE" = "yes" ];then
  {
  echo "---------deleteing snaps in same month------------"
  SNAPSHOT_ID=$(aws ec2 describe-snapshots --region $REGION --filters Name=tag:purpose,Values=non-prod-patching-"$PATCHING_CYCLE"-phase"$PHASE_NUMBER" --query 'Snapshots[*].SnapshotId' --output text)
  for i in $SNAPSHOT_ID
  do
  aws ec2 delete-snapshot --region $REGION --snapshot-id "$i";
  done
  }
  elif [ "$VALUE" = "no" ];then
  {
#  echo "---------deleteing snaps using snapshots-details-$PATCHING_CYCLE-phase$PHASE_NUMBER.txt-----------"
#  SNAPSHOT_ID=$(grep snap snapshots-details-"$PATCHING_CYCLE"-phase"$PHASE_NUMBER".txt)
echo "--------Enter File Name------"
read -r file_name
SNAPSHOT_ID=$(grep snap $file_name)
  for i in $SNAPSHOT_ID
  do
  aws ec2 delete-snapshot --region $REGION --snapshot-id "$i";
  done
  }
  else
    echo "Please enter valid input yes or no"
  fi
}
else
  echo "PHASE number must be a number and greater than 0."
fi

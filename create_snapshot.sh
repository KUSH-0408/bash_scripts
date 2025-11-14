#!/bin/sh
REGION=us-west-2 #replace region as per your requirement
DATE=$(date +%d%m%y%mm)
echo "Please enter patching month for e.g Aug, Sept, etc"
read -r input
PATCHING_MONTH=$(echo "$input" | cut -c 1-3 | sed -e "s/\b./\u\0/g") #Trims user input to first 3 chars & converts first char to uppercase
PATCHING_CYCLE=${PATCHING_MONTH}-$(date +%d%m%y-%H-%M)
echo "Please enter patching PHASE number i.e (1,2,3,...,etc.):"
read -r PHASE_NUMBER
if [ -n "$PHASE_NUMBER" ] && [ "$PHASE_NUMBER" -gt 0 ]
then
         FILENAME=snapshots-details-$PATCHING_CYCLE-phase$PHASE_NUMBER
          echo "----non-prod-patching-$PATCHING_CYCLE-phase$PHASE_NUMBER----" > "$FILENAME.txt"
           for i in $(cat IP.txt);
                    do
                             VOLUMEID=$(aws ec2 describe-instances --region us-west-2 --filters Name=private-ip-address,Values="$i" --query "Reservations[*].Instances[*].BlockDeviceMappings[?DeviceName == '/dev/sda1'].Ebs.VolumeId" --output text)
                              echo "----root volume backup of instance $i is started----" >> "$FILENAME.txt"
                               aws ec2 create-snapshot --region $REGION --description "$i"-root-"$DATE" --volume-id "$VOLUMEID" --tag-specifications "ResourceType=snapshot,Tags=[{Key=Purpose,Value=Patching}]"
                                aws ec2 describe-snapshots --region us-west-2 --filters Name=description,Values="$i"-root-"$DATE" --query 'Snapshots[*].SnapshotId' --output text >> "$FILENAME.txt";
                                 done
                         else
                                  echo "PHASE number must be a number and greater than 0."
fi

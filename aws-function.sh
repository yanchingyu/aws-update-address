#!/bin/bash
 
## setup timezone
sudo date -s "$(wget -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f5-8)Z" 1>/dev/null
## ALL of ip address info
ec2address=`aws ec2 describe-addresses`
## ALL of ip address id
allocationId=`echo $ec2address | jq -c '.Addresses | .[] | .AllocationId' | sed 's/\"//g'`

## help=`cat << EOF message EOF`; echo $help; ## message is not '\n' & space
help () {
    echo "readme: aws-update-address is the script to update the ip address "
    echo 
    echo "  -h                  display this help and exit"
    echo "  -n                  select your instance name"
    echo "  -a                  allocate ip add value ( limit 5 )"
    echo "  -r                  release ip all"
    echo "  -l                  loop count ( allocate -> run script -> release )"
    echo "  -g                  associate own ip of one and run script until all ip used"
    echo "  -t                  run script time ( default 3s )"
    echo 
    echo "Examples:"
    echo "  aws-update-address.sh -n first_instance_name -g"
    echo "  aws-update-address.sh -a 5"
    echo "  aws-update-address.sh -r"
    echo
    echo "  aws-update-address.sh -n first_instance_name -g -l 5 -t 5"
}

# allocate address
allocate () {
    for i in `seq 1 $1`
    do
        echo allocate ip $i
        allocateError=`aws ec2 allocate-address 2>&1 >/dev/null`
        if [ $? -ne 0 ]
        then
                echo $allocateError
        fi
    done
    echo
}

# release address
release () {
    for line in $allocationId
    do
        echo release ip $line
        releaseError=`aws ec2 release-address --allocation-id $line 2>&1 >/dev/null`
        if [ $? -ne 0 ]
        then
                echo $releaseError
        fi
    done
    echo
}

# associate address
## $1 => instance-id, $2 => loop count, $3 => script time
associate () {
    for i in `seq 1 $2`
    do
        echo loop $i:
        ## loop count >= 2, allocate max value
        if ! [ $2 -eq 1 ];then
            allocate 5
            ## ALL of ip address info
            ec2address=`aws ec2 describe-addresses`
            ## ALL of ip address id
            allocationId=`echo $ec2address | jq -c '.Addresses | .[] | .AllocationId' | sed 's/\"//g'`
        elif [ $2 -eq 1 ];then
            if [ -z "$allocationId" ];then
                echo "allocate ip, please"
            fi
        fi

        for line in $allocationId
        do
            echo associationId = $line
            associateError=`aws ec2 associate-address --instance-id $1 --allocation-id $line 2>&1 >/dev/null`
            
            if [ $? -ne 0 ]
            then
                    echo $associationError
                    exit 0
            fi
            sleep $3
        done
	echo

        ## loop count >= 2, release all ip 
        if ! [ $2 -eq 1 ];then
            release
        fi
    done  
}

#!/bin/bash
# https://docs.aws.amazon.com/zh_tw/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
# getopts References : https://www.cnblogs.com/kevingrace/p/11753294.html
# getopts References : https://www.cnblogs.com/kevingrace/p/11753294.html

## get aws ip function and variables releated
source ./aws-function.sh


usage() { echo "$0 usage: -h option"; exit 0; }
[ $# -eq 0 ] && usage

option=":n:a:l:t:rhg"

count=1         ## loop default 1
scriptTime=3    ## script run default time
have_g=0        ## is run associate instance & ip
while getopts $option optname
do
        ## $OPTIND => option address
        ## $OPTARG => option's value
        # echo $optname $OPTIND $OPTARG
        if [ $optname == g ];then
                have_g=1
                continue
        fi

        case $optname in
                h)
                        help
                        break
                        ;;
                n) 
                        instanceName=$OPTARG
                        echo instanceName = $instanceName
			echo
                        ;;
                a)
                # function allocate address add $OPTARG
                        allocate $OPTARG
                        ;;
                r)
                # function release address all
                        release
                        ;;
		l)
                # loop count
			count=$OPTARG
                        echo "loop count = $count"
			;;
                t)
                        scriptTime=$OPTARG
                        echo "time = $OPTARG"
                        ;;
                :)
                        echo "No argument value for option $OPTARG"
                        ;;
                ?)
                        echo "Unknown option $OPTARG"
                        ;;
                *)
                        help
                        echo "Unknown error while processing options"
                        ;;
        esac
done

## g run associate all ip 
if [ $have_g -eq 1 ];then
        ## value take from -n 
        instanceId=`aws ec2 describe-instances --filters "Name=tag:Name,Values=$instanceName" \
                        --query Reservations[*].Instances[*].[InstanceId] --output text`
        echo instanceId = $instanceId
# function associate address all
        associate $instanceId $count $scriptTime
fi

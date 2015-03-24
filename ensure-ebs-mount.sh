#!/bin/bash

# Usage: ensure-ebs-mount.sh key "secret" url instanceid volumeid ebsdevicetomount localdevicetomount
key=$1
secret="$2"
url=$3
instanceid=$4
volumeid=$5
ebsdevicetomount=$6
localdevicetomount=$7

res=$(euca-describe-volumes -I $key -S "$secret" --url $url --show-empty-fields $volumeid)
state=$(echo "$res" | grep VOLUME | awk '{print $6}')
inst=$(echo "$res" | grep ATTACHMENT | awk '{print $3}')
echo state=$state, inst=$inst

if [ $state == in-use ] && [ $inst != $instanceid ]
then
    echo Detaching instance
    euca-detach-volume -a $key -s "$secret" --url $url $volumeid
    
    timeout=60; counter=0
    until [ $state == available ] || [ $counter -ge $timeout ]
    do
        sleep 1; let counter=counter+1
        res=$(euca-describe-volumes -I $key -S "$secret" --url $url --show-empty-fields $volumeid)
        state=$(echo "$res" | grep VOLUME | awk '{print $6}')
        echo state=$state
    done
fi

timeout=60; counter=0
if [ $state == available ]
then

    echo Attaching instance
    euca-attach-volume -a $key -s "$secret" --url $url -i $instanceid -d $ebsdevicetomount $volumeid
    
    until ( [ $state == in-use ] && [ $inst == $instanceid ] && [ -b $localdevicetomount ] ) \
          || [ $counter -ge $timeout ]
    do
        sleep 1; let counter=counter+1
        res=$(euca-describe-volumes -I $key -S "$secret" --url $url --show-empty-fields $volumeid)
        state=$(echo "$res" | grep VOLUME | awk '{print $6}')
        inst=$(echo "$res" | grep ATTACHMENT | awk '{print $3}')
        echo state=$state, inst=$inst
    done
fi


[ $state == in-use ] && [ $inst == $instanceid ] && \
[ -b $localdevicetomount ] && [ $counter -le $timeout ]

exit $?
 

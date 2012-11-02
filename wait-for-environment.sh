#!/bin/bash

debug=no
debug() {
  if [ "$debug" == "yes" ]
  then
    echo $1
  fi
}

info=yes
info() {
  if [ "$info" == "yes" ]
  then
    echo $1
  fi
}

[ -z "$1" ] && echo "Usage: $0 <environment>" && exit 1

if [ -n "$2" ]
then
  branch=$2
else
  branch=master
fi

pushd $(dirname $0)/../.. &>/dev/null && BASE_DIR=$(pwd) && popd &>/dev/null
environment=$1
interval=1

found="no"
while [ "$found" == "no" ]
do
  debug "sleeping for $interval seconds..."
  sleep $interval
  
  # pull git repo
  pushd $BASE_DIR &>/dev/null
  git reset --hard &>/dev/null
  git clean -df &>/dev/null
  git checkout $branch &>/dev/null
  git pull origin $branch &>/dev/null
  popd &>/dev/null
  
  found="yes" # be optimistic
  for ip_file in $( find $BASE_DIR/state/$environment -name public-ipv4 )
  do  
    instance=$(echo $ip_file | sed 's/.*\/\([^\/]*\)\/meta-data\/.*/\1/g')
    if [[ $instance == i-* ]]
    then
      node=$(echo $ip_file | sed 's/.*\/\([^\/]*\)\/i-[^\/].*/\1/g')
      instance_commit=$(cat $BASE_DIR/state/$environment/$node/$instance/commit 2>/dev/null)
      [ "$instance_commit" == "" ] && instance_commit="unset"
    else
      node=$(echo $ip_file | sed 's/.*\/\([^\/]*\)\/meta-data\/.*/\1/g')
      instance_commit=$(cat $BASE_DIR/state/$environment/$node/commit 2>/dev/null)
      [ "$instance_commit" == "" ] && instance_commit="unset"
    fi
    ip=$(cat $ip_file)
    environment_commit=$(cat $BASE_DIR/state/$environment/commit 2>/dev/null)
    debug "$node has commit: \"$instance_commit\""

    if [ "$environment_commit" != "$instance_commit" ]
    then
      debug "$node is a suspect with \"$instance_commit\" not equal to \"$environment_commit\""
      if ping -q -w 4 -c 1 $ip &>/dev/null
      then
        # it does not match and the server is alive, so it is not yet ok
        debug "$node is alive and does not match, so we will continue waiting"
        info "waiting for $node..."
        found="no"
        break
      else
        debug "but $node is not alive, so we are not going to worry about the discrepancy"
      fi
    else
      debug "$node looks good, will continue"
    fi
    
  done #for

  let interval=interval+1
done #while

exit 0
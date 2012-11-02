#!/bin/bash

# Validate environment dependencies - these should be set in /etc/environment - exit if not
[ -z "${FACTER_iteego_environment}" ] && echo "FATAL: \$FACTER_iteego_environment not defined!" && exit 1
[ -z "${FACTER_iteego_branch}" ] && echo "FATAL: \$FACTER_iteego_branch not defined!" && exit 1

hostname=`hostname -s`

pushd /etc/puppet &>/dev/null
files/bin/getlock.pl /tmp/commit_state.lock $$
if [ $? == 0 ]; then

  # First of all, if our node does not have a state folder, create one
  if [ ! -d /etc/puppet/state/$FACTER_iteego_environment/$hostname ]
  then
    mkdir -p /etc/puppet/state/$FACTER_iteego_environment/$hostname
    touch /etc/puppet/state/$FACTER_iteego_environment/$hostname/readme.txt
  fi
  
  # If there are any file changes in our state folder, then push them back to origin
  pushd /etc/puppet/state/$FACTER_iteego_environment/$hostname &>/dev/null
  if [ $(git status --porcelain . | wc -l) -gt 0 ]
  then
    echo -n "$0: "
    date
    git add .
    git status --porcelain .
    git commit -m "Server State Change (${hostname})"
    git pull origin $FACTER_iteego_branch
    git push origin $FACTER_iteego_branch
  fi
  popd &>/dev/null
fi
popd &>/dev/null

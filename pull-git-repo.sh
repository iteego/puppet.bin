#!/bin/bash -u

# Validate environment dependencies - these should be set in /etc/environment - exit if not
[ -z "${FACTER_iteego_branch}" ] && echo "FATAL: \$FACTER_iteego_branch not defined!" && exit 1

pushd /etc/puppet &>/dev/null
branch_name=$(git symbolic-ref -q HEAD); branch_name=${branch_name##refs/heads/}; branch_name=${branch_name:-HEAD}
[ $branch_name == $FACTER_iteego_branch ] || git checkout $FACTER_iteego_branch

# Do a pull, but filter out lines we don't want to see in the puppet log
nice git pull | grep -v "github.com" | grep -v FETCH_HEAD | grep -v "Already up-to-date."
#nice git submodule init &>/dev/null
#nice git submodule update | grep "Submodule path"

popd &>/dev/null

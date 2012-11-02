#!/bin/bash
pushd /etc/puppet &>/dev/null
bin/getlock.pl /tmp/puppet_update.lock $$
if [ $? == 0 ]; then
  bin/pull-git-repo.sh
  if [ $? != 0 ]; then
    echo "Update failed (git-pull-repo.sh)"
    exit 1
  fi

  bin/puppet-apply.sh
  if [ $? != 0 ]; then
    echo "Update failed (puppet-apply.sh)"
    exit 2
  fi

  bin/commit-state.sh
  if [ $? != 0 ]; then
    echo "Update failed (commit-state.sh)"
    exit 3
  fi
fi
popd &>/dev/null

exit 0
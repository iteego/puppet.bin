#!/bin/bash
pushd /etc/puppet &>/dev/null
files/bin/getlock.pl /tmp/puppet_update.lock $$
if [ $? == 0 ]; then
  files/bin/pull-git-repo.sh
  if [ $? != 0 ]; then
    echo "Update failed (git-pull-repo.sh)"
    exit 1
  fi

  files/bin/puppet-apply.sh
  if [ $? != 0 ]; then
    echo "Update failed (puppet-apply.sh)"
    exit 2
  fi

  files/bin/commit-state.sh
  if [ $? != 0 ]; then
    echo "Update failed (commit-state.sh)"
    exit 3
  fi
fi
popd &>/dev/null

exit 0
#!/bin/bash

# Validate environment dependencies - these should be set in /etc/environment - exit if not
[ -z "${FACTER_iteego_environment}" ] \
  && echo "FATAL: \$FACTER_iteego_environment not defined!" \
  && exit 1

timeout -k 330 300 \
nice \
puppet apply \
    --environment=production \
    --modulepath /etc/puppet/modules \
    --templatedir /etc/puppet/templates \
    --logdest /var/log/puppet/puppet.log \
  /etc/puppet/manifests/init.pp

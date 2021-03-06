#!/usr/bin/env bash

########################################
# REQUIRED VARIABLES

# Will not continue without these...
[ -z "$ITEEGO_NODE" -o -z "$ITEEGO_REPO" -o -z "$RSA_KEY" ] && exit 255

# ITEEGO_NODE is the name of the puppet node to instantiate, like "storage"

# ITEEGO_REPO is a pointer back to the git repository
# containing the system manifests, for example:
# ITEEGO_REPO="git@github.com:iteego/iteego.system.git"

# RSA_KEY is used to connect to the back-end git server
# holding the system manifest.
# You can set the value before calling this script like this:
# RSA_KEY=\$(cat <<SETVAR
# ... key contents ...
# SETVAR)


########################################
# OPTIONAL VARIABLES / DEFAULTS

# ITEEGO_POLL_REPO is a flag, which when evaluates to true,
# causes this server to continuously poll the repo for changes
# The flag can be set to 1 (true) or anything else (false)
# If unset, the flag defaults to 0 (false)
[ -z "$ITEEGO_POLL_REPO" ] && ITEEGO_POLL_REPO=0

# ITEEGO_DOMAIN is the domain name one should affix to the node/server name
[ -z "$ITEEGO_DOMAIN" ] && ITEEGO_DOMAIN=iteego.com

# ITEEGO_POLL_SCHEDULE is the actual cron schedule string used to
# schedule the polling interval. This parameter is only relevant when
# ITEEGO_POLL_REPO has been set to 1 (true).
# The default value is "*/5 * * * *" (every 5 minutes)
[ -z "$ITEEGO_POLL_SCHEDULE" ] && ITEEGO_POLL_SCHEDULE="*/5 * * * *"

# ITEEGO_BRANCH is the name of the git branch we should use
[ -z "$ITEEGO_BRANCH" ] && ITEEGO_BRANCH=master

# ITEEGO_ENVIRONMENT is used to capture puppet environments
# most likely you will not need to use this
[ -z "$ITEEGO_ENVIRONMENT" ] && ITEEGO_ENVIRONMENT=production


########################################
# DO THE WORK

# Write base environment settings to our global /etc/environment file
# all scripts will depend on this file - it is global.
# use the puppet FACTER_xxx syntax so that the settings
# will becoe automatically available in puppet

# Information about our linux release (ubuntu/debian)
# Write all of the info from lsb-release into /etc/environment as puppet facts
# This will give puppet access to the information in a facter context when it runs
echo "export FACTER_distrib_id=$(lsb_release -i -s)" >>/etc/environment
echo "export FACTER_distrib_release=$(lsb_release -r -s)" >>/etc/environment
echo "export FACTER_distrib_codename=$(lsb_release -c -s)" >>/etc/environment
echo "export FACTER_distrib_description=\"$(lsb_release -d -s)\"" >>/etc/environment

# Filter environment and store as facter values in /etc/environment
set | grep ITEEGO | sed 's/\([^=]*\)=\(.*\)/export FACTER_\L\1=\2/g' >>/etc/environment

# Once all variables have been defined, load them up
. /etc/environment

# Make a log file for puppet
LOG_FILE=/var/log/puppet/puppet.log
touch $LOG_FILE
chmod 600 $LOG_FILE

# Puppet uses hostname -s to determine which node to run
echo "${FACTER_iteego_node}.${FACTER_iteego_domain}" >/etc/hostname
sed -i "s/\(127.0.0.1[[:space:]]*.*\)/\1 ${FACTER_iteego_node}.${FACTER_iteego_domain} ${FACTER_iteego_node}/g" /etc/hosts

# schedule puppet to run at reboot
echo 'SHELL=/bin/bash' >/tmp/.cron
echo 'MAILTO=admin@iteego.com' >>/tmp/.cron
echo '@reboot /etc/puppet/files/bin/update.sh &>> /var/log/puppet/puppet.log' >>/tmp/.cron
crontab /tmp/.cron
rm /tmp/.cron

# Do a system update and reboot
apt-get -q -y --force-yes dist-upgrade
shutdown -r now

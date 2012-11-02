#!/bin/bash
# Validate environment dependencies - these should be set in /etc/environment - exit if not
[ -z "${FACTER_iteego_environment}" ] && echo "FATAL: \$FACTER_iteego_environment not defined!" && exit 1
[ -z "${1}" ] && echo "FATAL: File name to watch not defined!" && exit 1

hostname=`hostname -s`

LOGFILE=/var/log/puppet/puppet.log
#TIMEOUT=30
LIST="${1}"
BASE_DIR="/etc/puppet/state/${FACTER_iteego_environment}/${hostname}"

pushd /etc/puppet &>/dev/null
files/bin/getlock.pl /tmp/watch_files.lock $$
if [ $? == 0 ]; then
#  should_update=0
  while /bin/true
  do
    if [ -e "${LIST}" ] && (( $(wc -l <"${LIST}") > 0 )) #if list exists and is not empty
    then
#      if [ $should_update == 0 ]
#      then
        for file in $(cat "${LIST}")
        do
          dest_dir=$(dirname "${BASE_DIR}${file}")
          if [ ! -d "${dest_dir}" ]
          then
            mkdir -p "${dest_dir}"
          fi
          if [ -d "${dest_dir}" ]
          then
            #TODO: Should we not cp here instead, with preservation of mode and permissions?
            cat $file > "${BASE_DIR}${file}"
          fi
        done
        /etc/puppet/files/bin/commit-state.sh &>> "${LOGFILE}"
#      fi
#      inotifywait -q -t $TIMEOUT -e modify,close_write --fromfile "${LIST}" &>> $LOGFILE; should_update=$?
       sleep 1
    else
      sleep 1
    fi
  done
fi
popd &>/dev/null

exit 0

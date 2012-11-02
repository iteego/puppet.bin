#!/bin/bash

# Validate environment dependencies - these should be set in /etc/environment - exit if not
[ -z "${FACTER_iteego_environment}" ] && echo "FATAL: \$FACTER_iteego_environment not defined!" && exit 1
hostname=`hostname -s`

pushd /etc/puppet &>/dev/null
bin/getlock.pl /tmp/service_deployment.lock $$
if [ $? == 0 ]; then

  # if artifact already exists and is the active artifact and service is running, exit 255
  #
  # create new folder named after commit hash
  # download all artifacts
  # unzip the zip files
  # shut down service by calling /etc/init.d/service stop
  # update symlinks by renaming the old symlink and creating a new one
  # start up service by calling /etc/init.d/service start
  # scan for success by calling /etc/init.d/service status (with timeout?)
  # if success, result=0, exit
  # if failure:
  #   shut down service by calling /etc/init.d/service stop
  #   revert symlinks by removing new symlink and renaming old symlink back
  #   remove new artifact
  #   if success, result=1, exit
  #   if failure, result-2, exit
  #
  # clear everything but the running artifact

  artifactory_base_url="http://gloin.iteego.com:7777/artifactory/libs-release-local/com/mrmaster"
  commit_container_file_name="commit"

  # Grab the artifacts from our desired commit, if we have not already done so

  environment_commit_file="/etc/puppet/state/${FACTER_iteego_environment}/${commit_container_file_name}"
  environment_commit=$(cat "${environment_commit_file}")
  [ -z "${environment_commit}" ] && echo "FATAL: no environment commit defined! Environment=[${FACTER_iteego_environment}]" && exit 1

  instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
  instance_commit_file="/etc/puppet/state/${FACTER_iteego_environment}/${hostname}/${instance_id}/${commit_container_file_name}"
  # If our state/environment/node/commit file does not exist, then we may be in a multi-node and our commit file is more one level down.
  if [ ! -e "${instance_commit_file}" ]
  then
    instance_commit_file="/etc/puppet/state/${FACTER_iteego_environment}/${hostname}/${commit_container_file_name}"
  fi

  service_dir=/opt/service
  old_commit=$(ls -l $service_dir | grep current | sed 's/.*\/\(.*\)/\1/')
  deployment_folder="/opt/service/version/${environment_commit}"
  old_deployment_folder="/opt/service/version/${old_commit}"

  # Make a folder for our new commit and pull it down
  # If the commit folder already exists, we will overwrite with what's in artifactory
  [ ! -d "${deployment_folder}" ] && mkdir -p "${deployment_folder}"
  pushd "${deployment_folder}" &>/dev/null
  url="${artifactory_base_url}/${environment_commit}/"
  if ! wget -nv -pr -nH --cut-dirs=5 -l 1 "${url}"; then echo "FATAL: Failed downloading artifacts from ${url}"; exit 1; fi
  find . -type f -iname "*.zip" -exec unzip -q -o "{}" \;
  [ ! -d webapp ] && mkdir webapp
  cp -p -f webapp-*.war webapp/mrgrails.war
  find . -type f -name "*.sh" -exec chmod +x "{}" \;
  popd &>/dev/null

  # tell the system we're doing maintenance
  touch /opt/service/maintenance_enabled

  # shut down our service
  [ -e /etc/init.d/service ] && /etc/init.d/service stop

  # update symlinks by renaming the old symlink and creating a new one
  # but only do it if we actually have a new version
  if [ "${environment_commit}" != "${old_commit}" ]
  then
    [ -h /opt/service/current ] && ( mv /opt/service/current /opt/service/previous || ( echo "FATAL: Failed renaming current symlink" && exit 1 ) )
    ln -s "${deployment_folder}" /opt/service/current
  fi

  # make sure that if we are running tomcat, we remove previous expanded webapp
  [ -d /var/lib/tomcat7/webapps/mrgrails ] && rm -fR /var/lib/tomcat7/webapps/mrgrails

  # start up our service, now with a new version
  [ -e /etc/init.d/service ] && /etc/init.d/service start

  # check for errors
  if [ -e /etc/init.d/service ] && /etc/init.d/service status
  then
    # status returned non-zero, i.e. we succeeded with update and startup
    # remove the old deployment
    # update the state repo
    [ -h /opt/service/previous ] && unlink /opt/service/previous
    [ ! -z $old_commit ] && [ "${environment_commit}" != "${old_commit}" ] && rm -fR "${old_deployment_folder}"
    instance_commit_dir=$(dirname "${instance_commit_file}")
    [ ! -d "${instance_commit_dir}" ] && mkdir -p "${instance_commit_dir}"
    cp -p -f "${environment_commit_file}" "${instance_commit_file}"

    if [ $(hostname -s) == "webapp" ]
    then
      t=300
      while ! curl -s localhost:8080/mrgrails/default/send | grep -q Copyright
      do
        sleep 1
        if [ $t -le 0 ]; then break; fi
        let t=t-1
      done
    fi

    # lastly, make sure to trigger an update so that the state repo gets quickly written back
    [ -e /etc/puppet/bin/commit-state.sh ] && nohup /etc/puppet/bin/commit-state.sh &>> /var/log/puppet/puppet.log &
  else
    #TODO: Further error handling needs to go here. What happens if we still fail to start up the old version?
    # status returned non-zero, i.e. we failed starting up
    [ -e /etc/init.d/service ] && /etc/init.d/service stop
    unlink /opt/service/current
    mv /opt/service/previous /opt/service/current
    rm -fR "${deployment_folder}"
    [ -e /etc/init.d/service ] && /etc/init.d/service start
  fi

  # tell the system maintenance is now over
  rm -f /opt/service/maintenance_enabled

fi
popd &>/dev/null

exit 0
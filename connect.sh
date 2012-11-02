#!/bin/bash

USAGE="$0 <environment> <node> [<instance>]"

# We require at least two parameters, as per the usage above

[ -z "${1}" ] && \
  echo "$USAGE" && \
  exit 101

[ -z "${2}" ] && \
  echo "$USAGE" && \
  exit 102

LOGIN_USER="root"

# This assumes our script lives in <repo_base>/bootstrap/bin
pushd $(dirname $0)/../.. &>/dev/null
base_repo_path=$(pwd)

instance_path="${base_repo_path}/state/${1}/${2}"

# if we got a third argument, that means we're looking for a multi-instance
if [ ! -z "${3}" ]; then
  instance_path="${instance_path}/${3}"
fi

ssh_key="${base_repo_path}/bootstrap/keys/id_rsa"

[ ! -e "${ssh_key}" ] && \
  echo "FATAL: SSH key \"${ssh_key}\" does not exist!" && \
  exit 201


if [ -d "${instance_path}/meta-data" ];
then
  instance_ip_file="${instance_path}/meta-data/public-hostname"
else
  # TODO: this is a hack that assumes only one media server exists in the repo
  for file in $(find $instance_path -name public-hostname); do
    instance_ip_file="${file}"
  done
fi

[ ! -e "${instance_ip_file}" ] && \
  echo "FATAL: No file with IP address was found at \"${instance_ip_file}\"!" && \
  exit 202

instance_ip=$(cat "${instance_ip_file}")
ssh -i "${ssh_key}" "${LOGIN_USER}"@"${instance_ip}"

popd &>/dev/null

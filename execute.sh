#!/bin/bash

USAGE="$0 <environment> <node> [<instance>] <command>"

# We require at least two parameters, as per the usage above

[ -z "${1}" ] && \
  echo "$USAGE" && \
  exit 101

[ -z "${2}" ] && \
  echo "$USAGE" && \
  exit 102

[ -z "${3}" ] && \
  echo "$USAGE" && \
  exit 103

LOGIN_USER="root"

# This assumes our script lives in <repo_base>/bootstrap/bin
pushd $(dirname $0)/../.. &>/dev/null
base_repo_path=$(pwd)

instance_path="${base_repo_path}/state/${1}/${2}"

# if we got a third argument, that means we're looking for a multi-instance
if [ -z "${4}" ]; then
  command="${3}"
else
  if [ -z "${4}" ]; then
    echo "$USAGE"
    exit 104
  fi
  instance_path="${instance_path}/${3}"
  command="${4}"
fi

ssh_key="${base_repo_path}/bootstrap/keys/id_rsa"
instance_ip_file="${instance_path}/meta-data/public-hostname"

[ ! -e "${ssh_key}" ] && \
  echo "FATAL: SSH key \"${ssh_key}\" does not exist!" && \
  exit 201

[ ! -e "${instance_ip_file}" ] && \
  echo "FATAL: No file with IP address was found at \"${instance_ip_file}\"!" && \
  exit 202

instance_ip=$(cat "${instance_ip_file}")
ssh -i "${ssh_key}" "${LOGIN_USER}"@"${instance_ip}" "${command}"

popd &>/dev/null

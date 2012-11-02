#!/bin/bash
BASE_URL="http://169.254.169.254/latest/meta-data"
instance_id=$(curl -s $BASE_URL/instance-id)
host_name="$(hostname -s)"

if [ "x${1}" == "xsingleton" ]
then
  DEST="/etc/puppet/state/${FACTER_iteego_environment}/${host_name}/meta-data"
else
  DEST="/etc/puppet/state/${FACTER_iteego_environment}/${host_name}/${instance_id}/meta-data"
fi
[ -d "${DEST}" ] || mkdir -p "${DEST}"
echo "${instance_id}" >"${DEST}/instance-id"
curl -s $BASE_URL/ami-id >"${DEST}/ami-id"
curl -s $BASE_URL/ami-launch-index >"${DEST}/ami-launch-index"
curl -s $BASE_URL/ami-manifest-path >"${DEST}/ami-manifest-path"
curl -s $BASE_URL/hostname >"${DEST}/hostname"
curl -s $BASE_URL/instance-action >"${DEST}/instance-action"
curl -s $BASE_URL/instance-type >"${DEST}/instance-type"
curl -s $BASE_URL/kernel-id >"${DEST}/kernel-id"
curl -s $BASE_URL/local-hostname >"${DEST}/local-hostname"
curl -s $BASE_URL/local-ipv4 >"${DEST}/local-ipv4"
curl -s $BASE_URL/mac >"${DEST}/mac"
curl -s $BASE_URL/profile >"${DEST}/profile"
curl -s $BASE_URL/public-hostname >"${DEST}/public-hostname"
curl -s $BASE_URL/public-ipv4 >"${DEST}/public-ipv4"
curl -s $BASE_URL/reservation-id >"${DEST}/reservation-id"
curl -s $BASE_URL/security-groups >"${DEST}/security-groups"

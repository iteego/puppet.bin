#!/bin/bash

# 
# Use this helper script to generate the user data text for any node. It simply
# prints the aws-data to stdout.
#
# Assuming you are on a mac and have pbcopy, invoke like so:
# ./make-user-data.sh environment node | pbcopy
#
# for example:
# ./make-user-data.sh staging webapp | pbcopy
#
# Then paste your buffer into the aws user-data field
#
# For each environment in your system, you need to create a sub-folder with the
# name of the environment. For each node class in your system, you need to
# create a file called "nodename.txt" under each environment and fill it with 
# relevant settings, like for example:
#
# production/git.txt:
# export ITEEGO_ENVIRONMENT=production
# export ITEEGO_NODE=git
# export ITEEGO_DOMAIN=iteego.com
#
# Your settings in the node definition file will override
# the default Iteego settings.
# 
# It is also required that you put a private key file in the keys directory.
# The default convention is to look for a key file called keys/id_rsa
# If your key file does not match this pattern, you should change code below.
# Note that the convention is to use RSA keys, not DSA. This may also be
# something you would prefer to change.
#
# Exit codes:
# 0 if successful
# 1 if environment and/or node undefined
# 2 if incorrect number of command line arguments
#
result=0
pushd `dirname $0`/.. &>/dev/null

if [ $# -ne 2 ]
then
  echo "Usage: $0 <environment> <node>"
  result=2
fi

if [ -d "${1}" -a -f "${1}/${2}.txt" ]
then
  echo "#!/bin/bash"
  user_data_file=$(mktemp -t user-data) 
  cat $1/$2.txt > $user_data_file
  echo "" >> $user_data_file
  echo "ITEEGO_RSA_KEY=\$(cat <<SETVAR" >> $user_data_file
  echo "$(cat keys/id_rsa)" >> $user_data_file
  echo "SETVAR" >> $user_data_file
  echo ")" >> $user_data_file
  echo "" >> $user_data_file
  cat bin/lib/user-data.txt >> $user_data_file
  echo "echo \"$(gzip -9 -c $user_data_file | base64)\" | base64 -d | gunzip -c | bash"
  #for debugging:
  #echo "$(gzip -9 -c $user_data_file | base64)" | base64 -D | gunzip -c
  rm $user_data_file
else
  echo "Based on the input parameters, you need to create a folder called \"${1}\" and inside it a file called \"${2}.txt\"."
  echo "The file should contain all variables you need for your user-data script."
  echo "Example file contents:"
  echo "export ITEEGO_ENVIRONMENT=production"
  echo "export ITEEGO_NODE=git"
  echo "export ITEEGO_DOMAIN=iteego.com"
  result=1
fi

popd &>/dev/null
exit $result
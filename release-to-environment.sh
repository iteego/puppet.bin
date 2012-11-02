#!/bin/bash
# The following takes the version tokens and releases them by checking them into the staging area in the puppet repository
# Any deployments will occur indirectly as a result of this change

debug=no
debug() {
  if [ $debug ]
  then
    echo $1
  fi
}

[ -z "$1" ] && echo "Usage: $0 <environment> <commit>" && exit 1
[ -z "$2" ] && echo "Usage: $0 <environment> <commit>" && exit 1

environment=$1
commit=$2
branch=master

[ -n "$3" ] && branch=$3

pushd $(dirname $0)/../.. &>/dev/null && BASE_DIR=$(pwd) && popd &>/dev/null
pushd "${BASE_DIR}/state/${environment}"
echo "$commit" > commit
if [ "$(git status --porcelain .)" ]
then
  echo "There were upstream changes. This release will commit those changes to the puppet repo"
  git add commit
  git commit -m "Automatic version deployment by ${JOB_NAME} build #${BUILD_NUMBER}"
  git pull origin $branch
  git push origin $branch
else
  echo "There were no upstream changes. This release will not commit any changes to the puppet repo."
fi
popd &>/dev/null
exit 0
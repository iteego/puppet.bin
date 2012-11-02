#!/bin/bash
# wait for an url matching a certain pattern
[ -z "$1" ] && echo "Usage: $0 <url> <pattern>" && exit 1
[ -z "$2" ] && echo "Usage: $0 <url> <pattern>" && exit 1
while ! curl -s $1 | grep -q -E $2; do sleep 1; done
exit 0
#!/usr/bin/env sh
# Usage: entrypoint.sh path_to_bin path_to_logfile
set -eu

rm -rf $2
touch $2
tail -F $2  >> /proc/1/fd/1 &

exec $1

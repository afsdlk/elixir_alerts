#!/bin/bash #-x

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "${BASE_DIR}/bin/config.sh"

USER=$MAIN_CONTAINER_USER_ID
TARGET=$MAIN_CONTAINER

if [ "$#" -eq 1 ]; then
  REST_STARTS_AT=1
fi

if [ "$#" -eq 2 ]; then
  TARGET=$1
  REST_STARTS_AT=2
fi

if [ "$#" -gt 2 ]; then
  USER=$1
  TARGET=$2
  REST_STARTS_AT=3
fi

docker exec -it $USER $TARGET bash -c "${@:$REST_STARTS_AT}"

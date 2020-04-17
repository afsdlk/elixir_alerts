#!/bin/bash #-x

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "${BASE_DIR}/bin/config.sh"

TARGET=${1:-$MAIN_CONTAINER}

docker logs -f $TARGET

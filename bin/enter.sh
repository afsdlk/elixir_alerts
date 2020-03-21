#!/bin/bash -x

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "${BASE_DIR}/bin/config.sh"

USER=${1:-$MAIN_CONTAINER_USER_ID}
TARGET=${2:-$MAIN_CONTAINER}

docker exec -it $USER $TARGET bash

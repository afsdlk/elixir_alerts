#!/bin/bash -x

# use compose.sh
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "${BASE_DIR}/bin/config.sh"

docker build --file $MAIN_DOCKERFILE -t $MAIN_IMAGE:latest "${BASE_DIR}"

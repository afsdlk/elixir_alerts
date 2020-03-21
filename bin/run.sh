#!/bin/bash -x

# use compose.sh
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "${BASE_DIR}/bin/config.sh"

docker run -t -d --rm $MAIN_CONTAINER_USER_ID $PORT_FORWARD $EXTRA_VOLUMES -v "$BASE_DIR/$HOST_ROOT":/$MAIN_ROOT --name $MAIN_CONTAINER $MAIN_IMAGE

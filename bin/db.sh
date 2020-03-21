#!/bin/bash -x

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${BASE_DIR}/config.sh"

"${BASE_DIR}/bin/exec.sh" "$DB_USER_ID" $DB_CONTAINER "psql -U postgres $DATABASE_NAME"

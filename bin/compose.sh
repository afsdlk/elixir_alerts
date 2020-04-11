#!/bin/bash -x

REMOVE_TEST_CONTAINERS=${1:-0}

(
cd "$( dirname "${BASH_SOURCE[0]}" )"
./stop.sh

if [ "$REMOVE_TEST_CONTAINERS" == "-d" ]; then
  docker-compose rm -fsv test_mysql
fi

docker-compose up --build
)

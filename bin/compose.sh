#!/bin/bash #-x

REMOVE_TEST_CONTAINERS=${1:-0}

(
reset
cd "$( dirname "${BASH_SOURCE[0]}" )"
./stop.sh

if [ "$REMOVE_TEST_CONTAINERS" == "-d" ]; then
  docker-compose rm -fsv test_mysql
  docker-compose rm -fsv test_postgres
  docker-compose rm -fsv gitserver
fi

docker-compose up --build
)

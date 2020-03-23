#!/bin/bash -x

(
cd "$( dirname "${BASH_SOURCE[0]}" )"
./stop.sh
docker-compose up --build
)

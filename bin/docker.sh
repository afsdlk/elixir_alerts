#!/bin/bash -x

(
cd "$( dirname "${BASH_SOURCE[0]}" )"

./stop.sh
./build.sh
./run.sh
./logs.sh
)

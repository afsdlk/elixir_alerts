#!/bin/bash #-x

(
reset

cd "$( dirname "${BASH_SOURCE[0]}" )"

./stop.sh
./remove.sh
./build.sh
./run.sh
./logs.sh
)

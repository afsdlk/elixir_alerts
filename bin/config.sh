#!/bin/bash

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

# App container information
MAIN_IMAGE="alerts_phoenix"
MAIN_CONTAINER="alerts_phoenix"
MAIN_CONTAINER_ROOT="app"
HOST_ROOT="alerts"
MAIN_DOCKERFILE="Dockerfile.PhoenixAlerts"

# Optional stuff for main app container information
MAIN_CONTAINER_USER_ID="-u 65534"
PORT_FORWARD="-p 4000:4000"
EXTRA_VOLUMES="-v dsman-home:/nonexistent"
EXTRA_MOUNT='files'
NETWORK="--network=alerts_default"

# Database container information
DB_USER_ID="-u postgres"
DB_CONTAINER="alerts_db"
DATABASE_NAME="alerts_dev"

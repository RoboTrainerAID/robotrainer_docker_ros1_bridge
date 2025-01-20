#!/bin/sh

CONTAINER_NAME=robotrainer_bridge

docker build \
    --build-arg UID="$(id -u)" \
    --build-arg GID="$(id -g)" \
    -t ${CONTAINER_NAME} \
    .
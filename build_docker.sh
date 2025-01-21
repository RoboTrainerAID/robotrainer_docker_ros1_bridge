#!/bin/sh

CONTAINER_NAME=robotrainer_bridge
CONTAINER_TAG=humble-ros1-bridge

docker build \
    --build-arg UID="$(id -u)" \
    --build-arg GID="$(id -g)" \
    -t ${CONTAINER_NAME}:${CONTAINER_TAG} \
    -f Dockerfile_with_base_image \
    .

    # --no-cache \
    # --progress plain \
    # --build-arg CACHE_BUST="$(date +%s)" \
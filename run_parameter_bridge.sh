#!/bin/bash
# Start ros1_bridge's parameter_bridge with the topic list in bridge_topics.yaml.
#
# Runs INSIDE the container, so nothing needs sourcing here: /ros_entrypoint.sh
# has already sourced ROS 2 and the bridge, and ROS 1 is installed under /usr.
#
# parameter_bridge takes its topic list from the ROS 1 parameter server and
# reads it once at startup, so the YAML has to be on the server before the
# bridge starts -- which means waiting for the ROS 1 master first.
set -e

CONFIG=${1:-/home/docker/bridge_config/bridge_topics.yaml}
MASTER_TIMEOUT=${MASTER_TIMEOUT:-60}

if [ ! -f "${CONFIG}" ]; then
    echo "Error: ${CONFIG} not found. Is the repository mounted at /home/docker/bridge_config?" >&2
    exit 1
fi

echo "Waiting for the ROS 1 master at ${ROS_MASTER_URI} (up to ${MASTER_TIMEOUT}s) ..."
waited=0
until rosparam list >/dev/null 2>&1; do
    if [ "${waited}" -ge "${MASTER_TIMEOUT}" ]; then
        echo "Error: no ROS 1 master at ${ROS_MASTER_URI} after ${MASTER_TIMEOUT}s." >&2
        exit 1
    fi
    sleep 1
    waited=$((waited + 1))
done

echo "Loading topic list from ${CONFIG}"
rosparam load "${CONFIG}"

exec ros2 run ros1_bridge parameter_bridge

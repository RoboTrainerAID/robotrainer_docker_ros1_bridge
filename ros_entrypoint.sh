#!/bin/bash
set -e

# setup ros2 environment
source /home/$USER/ros2_sources_ws/install/local_setup.sh
source /home/$USER/ros1_bridge/install/local_setup.sh
exec "$@"
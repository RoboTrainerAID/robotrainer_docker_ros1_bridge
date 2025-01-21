##############################################################################
##                                 Base Image                               ##
##############################################################################
# Ubuntu Jammy 22.04
FROM ubuntu:22.04
ENV TZ=Europe/Berlin
ENV TERM=xterm-256color
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install --no-install-recommends -y \
    locales \
    iputils-ping \
    sudo
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

##############################################################################
##                                 Create User                              ##
##############################################################################
ARG USER=docker
ARG PASSWORD=docker
ARG UID=1001
ARG GID=1001
ENV UID=${UID}
ENV GID=${GID}
ENV USER=${USER}
RUN groupadd -g "$GID" "$USER"  && \
    useradd -m -u "$UID" -g "$GID" --shell $(which bash) "$USER" -G sudo && \
    echo "$USER:$PASSWORD" | chpasswd && \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudogrp && \
    chmod 0440 /etc/sudoers.d/sudogrp && \
    chown ${UID}:${GID} -R /home/${USER}

##############################################################################
##                                 Build ROS2 from source                   ##
##############################################################################
# https://docs.ros.org/en/humble/Installation/Alternatives/Ubuntu-Development-Setup.html
ARG ROS_DISTRO=humble

# RUN apt update && apt upgrade && apt dist-upgrade

RUN apt-get update && apt-get install --no-install-recommends -y \
    software-properties-common \
    curl

RUN add-apt-repository universe
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
    | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt-get update && apt-get install --no-install-recommends -y \
    python3-flake8-docstrings \
    python3-pip \
    python3-pytest-cov \
    ros-dev-tools \
    python3-flake8-blind-except \
    python3-flake8-builtins \
    python3-flake8-class-newline \
    python3-flake8-comprehensions \
    python3-flake8-deprecated \
    python3-flake8-import-order \
    python3-flake8-quotes \
    python3-pytest-repeat \
    python3-pytest-rerunfailures

USER $USER 
RUN mkdir -p /home/$USER/ros2_sources_ws/src
WORKDIR /home/$USER/ros2_sources_ws

RUN vcs import --input https://raw.githubusercontent.com/ros2/ros2/humble/ros2.repos src

RUN sudo rosdep init
RUN rosdep update
RUN rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"
RUN touch /home/$USER/ros2_sources_ws/src/ros2/demos/image_tools/COLCON_IGNORE

RUN colcon build --symlink-install
# RUN echo "source /home/$USER/ros2_sources_ws/install/local_setup.bash" >> /etc/bash.bashrc

##############################################################################
##                                 Build ros1_bridge from source            ##
##############################################################################
# https://docs.ros.org/en/humble/How-To-Guides/Using-ros1_bridge-Jammy-upstream.html
USER root

RUN rm /etc/apt/sources.list.d/ros2.list
RUN apt-get remove -y \
    ros-dev-tools \
    && apt-get autoremove -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    cmake \
    git \
    python3-flake8 \
    python3-pytest \
    python3-setuptools \
    wget \
    ros-core-dev
    # python3-rosdep \

RUN python3 -m pip install -U colcon-common-extensions vcstool

USER $USER
RUN mkdir -p /home/$USER/ros1_bridge/src
WORKDIR /home/$USER/ros1_bridge/src
RUN git clone https://github.com/ros2/ros1_bridge

WORKDIR /home/$USER/ros1_bridge

RUN . ~/ros2_sources_ws/install/local_setup.sh && colcon build

##############################################################################
##                                 Build ROS and run                        ##
##############################################################################
# Set ROS2 DDS profile
COPY dds_profile.xml /home/$USER
RUN sudo chown $USER:$USER /home/$USER/dds_profile.xml
ENV FASTRTPS_DEFAULT_PROFILES_FILE=/home/$USER/dds_profile.xml

COPY ros_entrypoint.sh /
RUN sudo chmod +x /ros_entrypoint.sh
ENTRYPOINT ["/ros_entrypoint.sh"]

# CMD ["ros2", "run", "ros1_bridge", "dynamic_bridge", "--bridge-all-topics"]
# CMD ros2 run ros1_bridge dynamic_bridge --bridge-all-topics
CMD /bin/bash

# @author George Babarus
# @description Ubuntu image used for testing ansible playbooks with molecule. It will serve as a target for the molecule test.

ARG IMAGE_VERSION="latest"
ARG IMAGE_STAGE="ubuntu"

FROM ubuntu:$IMAGE_VERSION as ubuntu
LABEL maintainer="George Babarus"

ARG DEBIAN_FRONTEND=noninteractive

ENV pip_packages ""

# Install dependencies: OS and python
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       apt-utils \
       build-essential \
       locales \
       libffi-dev \
       libssl-dev \
       libyaml-dev \
       python3-dev \
       python3-setuptools \
       python3-pip \
       python3-yaml \
       rsyslog systemd systemd-cron sudo iproute2 \
    && apt remove python3-cryptography -y \
    && if [ ! -z $pip_packages ]; then pip3 install $pip_packages; fi \
    && pip install cryptography==41.0.5 --break-system-packages \
    && apt-get clean \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man

COPY bin/* /usr/local/bin/


FROM ubuntu as ubuntu_with_user

ARG APP_USER
ARG APP_USER_ID
ARG APP_GROUP
ARG APP_GROUP_ID
ARG APP_USER_HOME

RUN docker-users-create

USER $APP_USER_ID:$APP_GROUP_ID

# Set working directory
WORKDIR $APP_USER_HOME/$APP_USER

FROM $IMAGE_STAGE as ubuntu_final

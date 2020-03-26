#
#    Dockerized http://mediagoblin.org/
#    Copyright (C) Loic Dachary <loic@dachary.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

FROM debian:buster-20190910

# Set locale.
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update

# Install bootstrap and configure dependencies.
RUN apt-get install --yes \
      automake \
      git \
      nodejs \
      npm \
      python3-dev \
      virtualenv

# Install make and runtime dependencies.
RUN apt-get install --yes \
      python3-alembic \
      python3-celery \
      python3-jsonschema \
      python3-kombu \
      python3-lxml \
      python3-migrate  \
      python3-py \
      python3-pytest \
      python3-pytest-xdist \
      python3-six \
      python3-sphinx \
      python3-webtest

# Install audio dependencies.
RUN apt-get install --yes \
      gstreamer1.0-libav \
      gstreamer1.0-plugins-bad \
      gstreamer1.0-plugins-base \
      gstreamer1.0-plugins-good \
      gstreamer1.0-plugins-ugly \
      libsndfile1-dev \
      python3-gst-1.0 \
      python3-numpy \
      python3-scipy

# Install video dependencies.
RUN apt-get install --yes \
      gir1.2-gst-plugins-base-1.0 \
      gir1.2-gstreamer-1.0 \
      gstreamer1.0-tools \
      python3-gi

# Information for MediaGoblin system account.
ARG MEDIAGOBLIN_USER="mediagoblin"
ARG MEDIAGOBLIN_GROUP="mediagoblin"

ARG DOMAIN="mediagoblin.example.org"
ARG APP_ROOT="/srv/${DOMAIN}/mediagoblin"
ARG MEDIAGOBLIN_HOME_DIR="/var/lib/mediagoblin"

RUN set -xe && \
    groupadd "$MEDIAGOBLIN_GROUP" && \
    useradd \
      --comment "GNU MediaGoblin system account" \
      --home-dir "$MEDIAGOBLIN_HOME_DIR" \
      --create-home \
      --system \
      --gid "$MEDIAGOBLIN_GROUP" \
      "$MEDIAGOBLIN_USER" && \
    mkdir --parents "$APP_ROOT" && \
    chown \
      --no-dereference \
      --recursive \
      "${MEDIAGOBLIN_USER}:${MEDIAGOBLIN_GROUP}" "$APP_ROOT"

ARG MEDIAGOBLIN_DB_PATH="${MEDIAGOBLIN_HOME_DIR}/mediagoblin.db"

USER "$MEDIAGOBLIN_USER"
WORKDIR "$APP_ROOT"

ARG MEDIAGOBLIN_REPO="https://github.com/mtlynch/mediagoblin.git"
ARG MEDIAGOBLIN_BRANCH="2020-03-26"

RUN set -xe && \
    git clone "$MEDIAGOBLIN_REPO" . && \
    git checkout "$MEDIAGOBLIN_BRANCH" && \
    git submodule sync && \
    git submodule update --force --init --recursive && \
    ./bootstrap.sh && \
    VIRTUALENV_FLAGS='--system-site-packages' ./configure --with-python3 && \
    make

# Workaround for dependencies that make fails to install.
RUN set -xe && \
    ./bin/python setup.py develop --upgrade && \
    ./bin/pip install flup==1.0.3

RUN set -xe && \
    echo '[[mediagoblin.media_types.audio]]' >> mediagoblin.ini && \
    echo '[[mediagoblin.media_types.video]]' >> mediagoblin.ini

RUN set -xe && \
    chgrp \
      --no-dereference \
      --recursive \
      "$MEDIAGOBLIN_GROUP" "$MEDIAGOBLIN_HOME_DIR"

# Clean up.
USER root
RUN apt-get remove --yes \
    git-core && \
    rm -rf /var/lib/apt/lists/* && \
    rm -Rf /usr/share/doc && \
    rm -Rf /usr/share/man && \
    apt-get autoremove --yes && \
    apt-get clean

EXPOSE 6543

# Admin user in the MediaGoblin app.
ENV MEDIAGOBLIN_ADMIN_USER admin
ENV MEDIAGOBLIN_ADMIN_PASS admin
ENV MEDIAGOBLIN_ADMIN_EMAIL some@where.com

COPY entrypoint.sh /entrypoint.sh
USER "$MEDIAGOBLIN_USER"
CMD ["/entrypoint.sh"]

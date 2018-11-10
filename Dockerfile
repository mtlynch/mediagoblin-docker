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

FROM debian:jessie

# Set locale.
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update
RUN apt-get install -y \
      automake \
      gir1.2-gst-plugins-base-1.0 \
      gir1.2-gstreamer-1.0 \
      git-core \
      gstreamer1.0-libav \
      gstreamer1.0-plugins-bad \
      gstreamer1.0-plugins-good \
      gstreamer1.0-plugins-ugly \
      gstreamer1.0-tools \
      libasound2-dev \
      libgstreamer-plugins-base1.0-dev \
      libsndfile1-dev \
      nginx \
      nodejs-legacy \
      npm \
      poppler-utils \
      python \
      python3-gi \
      python-dev \
      python-gi \
      python-gst-1.0 \
      python-imaging \
      python-lxml \
      python-numpy \
      python-scipy \
      python-virtualenv \
      sudo

# Information for MediaGoblin system account.
ARG MEDIAGOBLIN_USER="mediagoblin"
ARG MEDIAGOBLIN_GROUP="mediagoblin"
ARG NGINX_GROUP="www-data"

ARG APP_ROOT="/srv/mediagoblin.example.org/mediagoblin"
ARG LOG_ROOT="/var/log/mediagoblin"
ARG MEDIAGOBLIN_HOME_DIR="/var/lib/mediagoblin"

RUN set -xe && \
    useradd \
      --comment "GNU MediaGoblin system account" \
      --home-dir "$MEDIAGOBLIN_HOME_DIR" \
      --create-home \
      --system \
      --gid "$NGINX_GROUP" \
      "$MEDIAGOBLIN_USER" && \
    groupadd "$MEDIAGOBLIN_GROUP" && \
    usermod --append --groups "$MEDIAGOBLIN_GROUP" "$MEDIAGOBLIN_USER" && \
    mkdir --parents "$LOG_ROOT" && \
    chown \
      --no-dereference \
      --recursive \
      "${MEDIAGOBLIN_USER}:${MEDIAGOBLIN_GROUP}" "$LOG_ROOT" && \
    mkdir --parents "$APP_ROOT" && \
    chown \
      --no-dereference \
      --recursive \
      "${MEDIAGOBLIN_USER}:${NGINX_GROUP}" "$APP_ROOT"

ADD nginx.conf /etc/nginx/sites-enabled/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN set -xe && \
    echo "$MEDIAGOBLIN_USER ALL=(ALL:ALL) NOPASSWD: /usr/sbin/nginx" \
      >> /etc/sudoers

USER "$MEDIAGOBLIN_USER"
WORKDIR "$APP_ROOT"

ARG MEDIAGOBLIN_REPO="http://git.savannah.gnu.org/r/mediagoblin.git"
ARG MEDIAGOBLIN_BRANCH="stable"
RUN set -xe && \
    git clone "$MEDIAGOBLIN_REPO" . && \
    git checkout "$MEDIAGOBLIN_BRANCH" && \
    git submodule sync && \
    git submodule update --force --init --recursive && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    bin/pip install scikits.audiolab && \
    bin/easy_install flup==1.0.3.dev-20110405 && \
    ln --symbolic "$MEDIAGOBLIN_HOME_DIR" user_dev && \
    cp --archive --verbose mediagoblin.ini mediagoblin_local.ini && \
    cp --archive --verbose paste.ini paste_local.ini && \
    sed \
      --in-place \
      "s@.*sql_engine = .*@sql_engine = sqlite:///${MEDIAGOBLIN_HOME_DIR}/mediagoblin.db@" \
      mediagoblin_local.ini && \
    echo '[[mediagoblin.media_types.video]]' >> mediagoblin_local.ini && \
    echo '[[mediagoblin.media_types.audio]]' >> mediagoblin_local.ini && \
    echo '[[mediagoblin.media_types.pdf]]' >> mediagoblin_local.ini && \
    chgrp \
      --no-dereference \
      --recursive \
      "$NGINX_GROUP" "$MEDIAGOBLIN_HOME_DIR"

# Clean up.
USER root
RUN apt-get remove --yes \
    automake \
    git-core && \
    rm -rf /var/lib/apt/lists/* && \
    rm -Rf /usr/share/doc && \
    rm -Rf /usr/share/man && \
    apt-get autoremove --yes && \
    apt-get clean

USER "$MEDIAGOBLIN_USER"

EXPOSE 80

# Copy build args to environment variables so that they're accessible in CMD.
ENV NGINX_GROUP "$NGINX_GROUP"

# Admin user in the MediaGoblin app.
ENV MEDIAGOBLIN_ADMIN_USER admin
ENV MEDIAGOBLIN_ADMIN_PASS admin
ENV MEDIAGOBLIN_ADMIN_EMAIL some@where.com

CMD sudo nginx && \
    bin/gmg dbupdate && \
    `# Ignore failure to add admin because they may already exist.` && \
    { \
      bin/gmg adduser \
        --username "$MEDIAGOBLIN_ADMIN_USER" \
        --password "$MEDIAGOBLIN_ADMIN_PASS" \
        --email "$MEDIAGOBLIN_ADMIN_EMAIL" && \
      bin/gmg makeadmin "$MEDIAGOBLIN_ADMIN_USER"; \
    } || true && \
    ./lazyserver.sh \
      --server-name=fcgi \
      fcgi_host=127.0.0.1 \
      fcgi_port=26543

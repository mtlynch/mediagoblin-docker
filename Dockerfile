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

FROM debian:stretch

# Set locale.
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Set locale.
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get update
RUN apt-get install --yes \
      automake \
      curl \
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
      mercurial \
      nginx \
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
      rsync \
      sudo && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install --yes nodejs

ARG GCSFUSE_REPO="gcsfuse-jessie"
ARG GCS_MOUNT_ROOT="/mnt/gcsfuse"
RUN apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl && \
    echo "deb http://packages.cloud.google.com/apt $GCSFUSE_REPO main" \
      | tee /etc/apt/sources.list.d/gcsfuse.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | apt-key add -
RUN apt-get update
RUN apt-get install --yes gcsfuse && \
    echo 'user_allow_other' > /etc/fuse.conf

# Install entr.
ARG ENTR_ROOT="/var/lib/entr"
ARG ENTR_VERSION="4.1"
RUN set -xe && \
    mkdir --parents "$ENTR_ROOT" && \
    cd "$ENTR_ROOT" && \
    hg clone https://bitbucket.org/eradman/entr . && \
    hg checkout "entr-${ENTR_VERSION}" && \
    ./configure && \
    make install

# Information for MediaGoblin system account.
ARG MEDIAGOBLIN_USER="mediagoblin"
ARG MEDIAGOBLIN_GROUP="mediagoblin"
ARG NGINX_GROUP="www-data"

ARG DOMAIN="mediagoblin.example.org"
ARG APP_ROOT="/srv/${DOMAIN}/mediagoblin"
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
      "${MEDIAGOBLIN_USER}:${NGINX_GROUP}" "$APP_ROOT" && \
    mkdir --parents "$GCS_MOUNT_ROOT" && \
    chown \
      --no-dereference \
      "${MEDIAGOBLIN_USER}:www-data" "$GCS_MOUNT_ROOT"

# Configure nginx.
ARG HTTP_AUTH_USER='user'
ARG HTTP_AUTH_PASS='pass'
ARG GCS_BUCKET="REPLACE-WITH-YOUR-GCS-BUCKET-NAME"
ADD nginx.conf.tmpl /tmp/nginx.conf.tmpl
RUN set -xe && \
    envsubst '${DOMAIN},${APP_ROOT},${GCS_BUCKET}' < /tmp/nginx.conf.tmpl \
      > /etc/nginx/sites-enabled/nginx.conf && \
    rm /etc/nginx/sites-enabled/default && \
    python -c "import crypt; print '$HTTP_AUTH_USER:%s' % crypt.crypt('$HTTP_AUTH_PASS', '\$6\$saltysalt348982553')" >> /etc/nginx/.htpasswd && \
    echo "$MEDIAGOBLIN_USER ALL=(ALL:ALL) NOPASSWD: /usr/sbin/nginx" \
      >> /etc/sudoers

USER "$MEDIAGOBLIN_USER"
WORKDIR "$APP_ROOT"

ARG MEDIAGOBLIN_DB_PATH="${MEDIAGOBLIN_HOME_DIR}/mediagoblin.db"
ARG MEDIAGOBLIN_REPO="https://github.com/mtlynch/mediagoblin.git"
ARG MEDIAGOBLIN_BRANCH="mtlynch-custom"
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
    git clone https://github.com/ayleph/mediagoblin-basicsearch.git && \
    cp --recursive mediagoblin-basicsearch/basicsearch mediagoblin/plugins/ && \
    rm -rf mediagoblin-basicsearch && \
    cp --archive --verbose mediagoblin.ini mediagoblin_local.ini && \
    cp --archive --verbose paste.ini paste_local.ini && \
    sed \
      --in-place \
      "s@.*sql_engine = .*@sql_engine = sqlite:///${MEDIAGOBLIN_DB_PATH}@" \
      mediagoblin_local.ini && \
    echo '[[mediagoblin.plugins.basicsearch]]' >> mediagoblin_local.ini && \
    echo '[[mediagoblin.media_types.video]]' >> mediagoblin_local.ini && \
    echo '[[[skip_transcode]]]' >> mediagoblin_local.ini && \
    echo 'mime_types = video/webm, video/ogg, video/mp4, audio/ogg, application/ogg, application/x-annodex' >> mediagoblin_local.ini && \
    echo 'container_formats = Matroska, Ogg, ISO MP4/M4A' >> mediagoblin_local.ini && \
    echo 'video_codecs = d, VP8 video, VP9 video, Theora, H.264, H.264 / AVC, MPEG-4 video' >> mediagoblin_local.ini && \
    echo 'audio_codecs = Opus, Vorbis, MPEG-4 AAC, MPEG-4 AAC audio' >> mediagoblin_local.ini && \
    echo 'dimensions_match = false' >> mediagoblin_local.ini && \
    chgrp \
      --no-dereference \
      --recursive \
      "$NGINX_GROUP" "$MEDIAGOBLIN_HOME_DIR"

# Clean up.
USER root
RUN apt-get remove --yes \
    automake \
    git-core \
    mercurial && \
    rm -rf /var/lib/apt/lists/* && \
    rm -Rf /usr/share/doc && \
    rm -Rf /usr/share/man && \
    apt-get autoremove --yes && \
    apt-get clean

USER "$MEDIAGOBLIN_USER"

EXPOSE 80

# Copy build args to environment variables so that they're accessible in CMD.
ENV NGINX_GROUP "$NGINX_GROUP"
ENV GCS_MOUNT_ROOT "$GCS_MOUNT_ROOT"
ENV MEDIAGOBLIN_DB_PATH "$MEDIAGOBLIN_DB_PATH"

ENV GCS_BUCKET "$GCS_BUCKET"

ENV MEDIAGOBLIN_MEDIA_DIR "${MEDIAGOBLIN_HOME_DIR}/media"
ENV MEDIAGOBLIN_PUBLIC_DIR "${MEDIAGOBLIN_MEDIA_DIR}/public"
ENV GCS_PUBLIC_DIR "${GCS_MOUNT_ROOT}/media/public"
ENV GCS_DB_PATH "${GCS_MOUNT_ROOT}/mediagoblin.db"

# Admin user in the MediaGoblin app.
ENV MEDIAGOBLIN_ADMIN_USER admin
ENV MEDIAGOBLIN_ADMIN_PASS admin
ENV MEDIAGOBLIN_ADMIN_EMAIL some@where.com

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

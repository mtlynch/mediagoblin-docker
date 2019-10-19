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

# Install nginx
RUN apt-get install --yes nginx

# Install gettext (for the envsubst command)
RUN apt-get install --yes gettext

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
      "${MEDIAGOBLIN_USER}:${NGINX_GROUP}" "$APP_ROOT"

# Configure nginx.
ARG HTTP_AUTH_USER='user'
ARG HTTP_AUTH_PASS='pass'
ARG GCS_BUCKET="REPLACE-WITH-YOUR-GCS-BUCKET-NAME"

RUN set -xe && \
    python -c "import crypt; print '$HTTP_AUTH_USER:%s' % crypt.crypt('$HTTP_AUTH_PASS', '\$6\$saltysalt348982553')" >> /etc/nginx/.htpasswd

ARG MEDIAGOBLIN_DB_URL="REPLACE-WITH-YOUR-DB-URL"
ARG MEDIAGOBLIN_DB_PATH="${MEDIAGOBLIN_HOME_DIR}/mediagoblin.db"
ADD "$MEDIAGOBLIN_DB_URL" "$MEDIAGOBLIN_DB_PATH"
RUN chown "$MEDIAGOBLIN_USER" "$MEDIAGOBLIN_DB_PATH" && \
    chmod 400 "$MEDIAGOBLIN_DB_PATH"

USER "$MEDIAGOBLIN_USER"
WORKDIR "$APP_ROOT"

ARG MEDIAGOBLIN_REPO="https://github.com/mtlynch/mediagoblin.git"
ARG MEDIAGOBLIN_BRANCH="mtlynch-custom"
ARG HTML_TITLE="GNU MediaGoblin"

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

# Install basicsearch plugin
RUN set -xe && \
    ln --symbolic "$MEDIAGOBLIN_HOME_DIR" user_dev && \
    git clone https://github.com/ayleph/mediagoblin-basicsearch.git && \
    cp --recursive mediagoblin-basicsearch/basicsearch mediagoblin/plugins/ && \
    rm -rf mediagoblin-basicsearch

COPY mediagoblin.ini mediagoblin.ini
RUN set -xe && \
    sed \
      --in-place \
      "s@.*sql_engine = .*@sql_engine = sqlite:///${MEDIAGOBLIN_DB_PATH}@" \
      mediagoblin.ini && \
    sed \
      --in-place \
      "s@.*html_title = .*@html_title = ${HTML_TITLE}@" \
      mediagoblin.ini && \
    chgrp \
      --no-dereference \
      --recursive \
      "$NGINX_GROUP" "$MEDIAGOBLIN_HOME_DIR"

USER root

# Clean up.
RUN apt-get remove --yes \
    git-core && \
    rm -rf /var/lib/apt/lists/* && \
    rm -Rf /usr/share/doc && \
    rm -Rf /usr/share/man && \
    apt-get autoremove --yes && \
    apt-get clean

ENV PORT 80
EXPOSE "$PORT"

# Copy build args to environment variables so that they're accessible in CMD.
ENV DOMAIN "$DOMAIN"
ENV APP_ROOT "$APP_ROOT"
ENV NGINX_GROUP "$NGINX_GROUP"
ENV MEDIAGOBLIN_USER "$MEDIAGOBLIN_USER"
ENV MEDIAGOBLIN_DB_PATH "$MEDIAGOBLIN_DB_PATH"

ENV GCS_BUCKET "$GCS_BUCKET"

ENV MEDIAGOBLIN_MEDIA_DIR "${MEDIAGOBLIN_HOME_DIR}/media"
ENV MEDIAGOBLIN_PUBLIC_DIR "${MEDIAGOBLIN_MEDIA_DIR}/public"

# Admin user in the MediaGoblin app.
ENV MEDIAGOBLIN_ADMIN_USER admin
ENV MEDIAGOBLIN_ADMIN_PASS admin
ENV MEDIAGOBLIN_ADMIN_EMAIL some@where.com

ARG NGINX_CONFIG_TEMPLATE="/etc/nginx/conf.d/default.conf.tmpl"
ENV NGINX_CONFIG_TEMPLATE "$NGINX_CONFIG_TEMPLATE"
COPY default.conf.tmpl "$NGINX_CONFIG_TEMPLATE"
COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh entrypoint.sh
COPY init-mediagoblin.sh init-mediagoblin.sh
CMD ["./entrypoint.sh"]

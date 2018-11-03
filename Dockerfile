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
RUN useradd \
      --comment "GNU MediaGoblin system account" \
      --home-dir /var/lib/mediagoblin \
      --create-home \
      --system \
      --gid www-data \
      mediagoblin && \
    groupadd mediagoblin && \
    usermod --append --groups mediagoblin mediagoblin && \
    mkdir --parents /var/log/mediagoblin && \
    chown \
      --no-dereference \
      --recursive \
      mediagoblin:mediagoblin /var/log/mediagoblin && \
    mkdir --parents /srv/mediagoblin.example.org/mediagoblin && \
    chown \
      --no-dereference \
      --recursive \
      mediagoblin:www-data /srv/mediagoblin.example.org/mediagoblin

USER mediagoblin
WORKDIR /srv/mediagoblin.example.org/mediagoblin

RUN git clone https://github.com/mtlynch/mediagoblin.git . && \
    git checkout docker-friendly && \
    git submodule sync && \
    git submodule update --force --init --recursive && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    bin/easy_install flup==1.0.3.dev-20110405 && \
    ln --symbolic /var/lib/mediagoblin user_dev && \
    cp --archive --verbose mediagoblin.ini mediagoblin_local.ini && \
    cp --archive --verbose paste.ini paste_local.ini && \
    perl -pi -e 's|.*sql_engine = .*|sql_engine = sqlite:////var/lib/mediagoblin/mediagoblin.db|' mediagoblin_local.ini

USER root
RUN echo '[[mediagoblin.media_types.video]]' | sudo -u mediagoblin tee -a mediagoblin_local.ini
RUN echo '[[mediagoblin.media_types.audio]]' | sudo -u mediagoblin tee -a mediagoblin_local.ini
RUN sudo -u mediagoblin bin/pip install scikits.audiolab
RUN echo '[[mediagoblin.media_types.pdf]]' | sudo -u mediagoblin tee -a mediagoblin_local.ini

ADD docker-nginx.conf /etc/nginx/sites-enabled/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

EXPOSE 80

ADD docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

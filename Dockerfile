FROM ubuntu:22.04

ARG ANKI_VERSION=23.12.1
ARG QT_VERSION=6

RUN apt update && DEBIAN_FRONTEND=noninteractive \
    apt install --no-install-recommends --assume-yes \
        wget zstd xdg-utils mpv locales ca-certificates curl git build-essential libxcb-xinerama0 libxcb-cursor0 libnss3 \
        libxcomposite-dev libxdamage-dev libxtst-dev libxkbcommon-dev libxkbfile-dev
RUN useradd -m anki

# Download Anki
RUN mkdir /app
RUN chown -R anki /app
WORKDIR /app

RUN wget -O ANKI.tar.zst https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}.tar.zst
RUN zstd -d ANKI.tar.zst && rm ANKI.tar.zst && \
    tar xfv ANKI.tar && rm ANKI.tar
WORKDIR /app/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}

RUN cat install.sh | sed 's/xdg-mime/#/' > install_modified.sh
RUN /bin/bash ./install_modified.sh

# Post process
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 \ LANGUAGE=en_US \ LC_ALL=en_US.UTF-8

# Cleanup
RUN apt-get remove -y build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Anki prep
ADD data /data
RUN mkdir /data/addons21
RUN chown -R anki /data
VOLUME /data

RUN mkdir /export
RUN chown -R anki /export
VOLUME /export

# Plugin installation
WORKDIR /app
RUN git clone -n --depth=1 --filter=tree:0 \
        https://git.foosoft.net/alex/anki-connect.git && \
        cd anki-connect && git sparse-checkout set --no-cone plugin && git checkout
RUN ln -s -f /app/anki-connect/plugin /data/addons21/AnkiConnectDev

USER anki

ENV QMLSCENE_DEVICE softwarecontext
ENV QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
ENV QT_QPA_PLATFORM="vnc"
# Could also use "offscreen"

WORKDIR /app/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}
CMD ["anki", "-b", "/data"]
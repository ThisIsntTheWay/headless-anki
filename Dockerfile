FROM debian:12.4-slim

ARG ANKI_VERSION=23.12.1
ARG QT_VERSION=6

RUN apt update && apt install --no-install-recommends -y \
        wget zstd mpv locales curl git ca-certificates jq libxcb-xinerama0 libxcb-cursor0 libnss3 \
        libxcomposite-dev libxdamage-dev libxtst-dev libxkbcommon-dev libxkbfile-dev
RUN useradd -m anki

# Anki installation
RUN mkdir /app && chown -R anki /app
WORKDIR /app

RUN wget -O ANKI.tar.zst --no-check-certificate https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}.tar.zst && \
    zstd -d ANKI.tar.zst && rm ANKI.tar.zst && \
    tar xfv ANKI.tar && rm ANKI.tar
WORKDIR /app/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}

# Run modified install.sh
RUN cat install.sh | sed 's/xdg-mime/#/' | sh -

# Post process
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 \ LANGUAGE=en_US \ LC_ALL=en_US.UTF-8

RUN apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Anki volumes
ADD data /data
RUN mkdir /data/addons21 && chown -R anki /data
VOLUME /data

RUN mkdir /export && chown -R anki /export
VOLUME /export

# Plugin installation
WORKDIR /app
RUN git clone -n --depth=1 --filter=tree:0 \
        https://git.foosoft.net/alex/anki-connect.git && \
        cd anki-connect && git sparse-checkout set --no-cone plugin && git checkout
RUN ln -s -f /app/anki-connect/plugin /data/addons21/AnkiConnectDev

# Edit AnkiConnect config
RUN jq '.webBindAddress = "0.0.0.0"' /data/addons21/AnkiConnectDev/config.json > tmp_file && \
    mv tmp_file /data/addons21/AnkiConnectDev/config.json

USER anki

ENV QMLSCENE_DEVICE softwarecontext
ENV QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
ENV QT_QPA_PLATFORM="vnc"
# Could also use "offscreen"

WORKDIR /app/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}
CMD ["anki", "-b", "/data"]
FROM debian:12.4-slim

ARG ANKICONNECT_VERSION=25.2.25.0
ARG ANKI_VERSION=25.02.4
ARG QT_VERSION=6

RUN apt update && apt install --no-install-recommends -y \
        wget zstd mpv locales curl git ca-certificates jq libxcb-xinerama0 libxcb-cursor0 libnss3 \
        libxcomposite-dev libxdamage-dev libxtst-dev libxkbcommon-dev libxkbfile-dev
RUN useradd -m anki

# Anki installation
RUN mkdir /app && chown -R anki /app
COPY startup.sh /app/startup.sh
WORKDIR /app

RUN apt install -y \
  python3-pyqt6.qtquick \
  python3-pyqt6.qtwebengine \
  python3-pyqt6.qtmultimedia \
  python3-venv

RUN python3 -m venv --system-site-packages pyenv
RUN pyenv/bin/pip install --upgrade pip
RUN pyenv/bin/pip install --upgrade --pre aqt

# Anki volumes
ADD data /data
RUN mkdir /data/addons21 && chown -R anki /data
VOLUME /data

RUN mkdir /export && chown -R anki /export
VOLUME /export

# Plugin installation
WORKDIR /app
RUN curl -L https://git.sr.ht/~foosoft/anki-connect/archive/${ANKICONNECT_VERSION}.tar.gz | \
    tar -xz && \
    mv anki-connect-${ANKICONNECT_VERSION} anki-connect
RUN chown -R anki:anki /app/anki-connect/plugin && \
    ln -s -f /app/anki-connect/plugin /data/addons21/AnkiConnectDev

# Edit AnkiConnect config
RUN jq '.webBindAddress = "0.0.0.0"' /data/addons21/AnkiConnectDev/config.json > tmp_file && \
    mv tmp_file /data/addons21/AnkiConnectDev/config.json

USER anki

ENV ANKICONNECT_WILDCARD_ORIGIN="0"
ENV QMLSCENE_DEVICE=softwarecontext
ENV FONTCONFIG_PATH=/etc/fonts
ENV QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
ENV QT_QPA_PLATFORM="vnc"
# Could also use "offscreen"

CMD ["/bin/bash", "startup.sh"]

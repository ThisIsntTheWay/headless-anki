ARG ANKICONNECT_VERSION=25.11.9.0
ARG ANKI_VERSION=25.02.7
ARG QT_VERSION=6

# --- Build: Install Anki and AnkiConnect ---
FROM debian:13-slim AS build
ARG ANKICONNECT_VERSION
ARG ANKI_VERSION
ARG QT_VERSION

RUN apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates curl zstd \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    # Anki desktop bundle -> /usr/local
    curl -fL -o /tmp/anki.tar.zst \
        "https://github.com/ankitects/anki/releases/download/${ANKI_VERSION}/anki-${ANKI_VERSION}-linux-qt${QT_VERSION}.tar.zst"; \
    mkdir -p /tmp/anki; \
    tar -x --zstd -f /tmp/anki.tar.zst -C /tmp/anki --strip-components=1; \
    ( cd /tmp/anki && sed 's/xdg-mime/#/' install.sh | sh - ); \
    # AnkiConnect plugin
    mkdir -p /app/anki-connect; \
    curl -fL "https://git.sr.ht/~foosoft/anki-connect/archive/${ANKICONNECT_VERSION}.tar.gz" \
        | tar -xz -C /app/anki-connect --strip-components=1

# --- Final stage ---
FROM debian:13-slim

# Dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates jq mpv \
        libnss3 libxcb-xinerama0 libxcb-cursor0 \
        libxcomposite1 libxdamage1 libxtst6 libxkbcommon0 libxkbfile1 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN useradd -m anki && mkdir /app && chown anki /app
WORKDIR /app

COPY --from=build /usr/local /usr/local
COPY --from=build /app/anki-connect /app/anki-connect
COPY startup.sh /app/startup.sh

# Anki profile + AnkiConnect wiring
ADD data /data
RUN mkdir -p /data/addons21 /export \
    && ln -sf /app/anki-connect/plugin /data/addons21/AnkiConnectDev \
    && jq '.webBindAddress = "0.0.0.0"' /app/anki-connect/plugin/config.json > /tmp/c \
    && mv /tmp/c /app/anki-connect/plugin/config.json \
    && chown -R anki:anki /app /data /export
VOLUME /data
VOLUME /export

USER anki

ENV ANKICONNECT_WILDCARD_ORIGIN="0"
ENV QMLSCENE_DEVICE=softwarecontext
ENV FONTCONFIG_PATH=/etc/fonts
ENV QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
ENV QT_QPA_PLATFORM="vnc"
# Could also use "offscreen"

CMD ["/bin/bash", "/app/startup.sh"]

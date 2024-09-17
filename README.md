# Headless Anki
Headless Anki with the AnkiConnect plugin installed.  
Useful in automation workflows.

The default user profile is as barebones as it can get.

The following volumes are exposed and can be mounted by the user:
- `/data`: Anki data (Profile, decks etc.).
- `/export`: Path that can be used for exporting Anki decks, e.g. using the AnkiConnect API.

## Usage
To run, execute:
```bash
docker run -d -p 8765:8765 -v $(pwd)/export:/export thisisnttheway/headless-anki:latest
```

To bring your own Anki profile, mount it on `/data` in the container:
```bash
docker run -d -v ~/.local/share/Anki2:/data thisisnttheway/headless-anki:latest
```

> [!WARNING]
> If you do bring your own profile, make sure that your AnkiConnect configuration doesn't have a listen address of `localhost`

> [!TIP] 
> Launch the container with the environment var `ANKICONNECT_WILDCARD_ORIGIN=1` to set `webCorsOriginList` in AnkiConnects config to `["*"]`.  
> **This will modify your existing config** if you bring your own profile!  Your existing config file will be backed up to `config.json_bak_ha` first, however.  
> - If this ENV var is unset/not equal to 0, this backup will be restored (if existing)

You can also use other QT platform plugins by setting the env var `QT_QPA_PLATFORM`:
```bash
docker run -e QT_QPA_PLATFORM="offscreen" ...
```

By default, Anki will be launched using `QT_QPA_PLATFORM="vnc"`.  
This will enable Anki to be accessed using a VNC viewer which might help with debugging, provided port `5900` is forwarded:  
![](images/vnc_gui.png)

## Building
To quickly build the image yourself, issue:
```bash
docker build --progress=plain . -t headless-anki:test
```

Different versions of each component (Anki, QT, AnkiConnect) can be installed.  
Supply those versions as build flags:
```bash
docker build \
    --build-arg ANKICONNECT_VERSION=24.7.25.0 \
    --build-arg ANKI_VERSION=24.06.3 \
    --build-arg QT_VERSION=6 \
    -t headless-anki:test \
    .
```

For available versions, refer to:
- [Anki GitHub releases](https://github.com/ankitects/anki/releases)
- [AnkiConnect releases](https://git.foosoft.net/alex/anki-connect/releases)

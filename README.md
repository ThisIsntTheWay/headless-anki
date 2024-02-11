# Headless Anki
Headless Anki with the AnkiConnect plugin installed.  
The goal of this thing is to have a headless Anki instance ready for use in automation workflows.  

The default user profile is as barebones as it could get.

Creates the following volumes that could be further exposed by the user:
- `/data`: Anki data (Profile, decks etc.).
- `/export`: Potential folder to be used for exporting Anki decks, e.g. using the AnkiConnect API.

## Usage
To run, execute:
```bash
docker run -d -p 5900:5900 -p 8765:8765 -v $(pwd)/export:/export thisisnttheway/headless-anki:latest
#             ^^^^^^^^^^^^ if using QT_QPA_PLATFORM="vnc"
```

You can also use other QT platform plugins by setting the env var `QT_QPA_PLATFORM`:
```bash
docker run -e QT_QPA_PLATFORM="offscreen" ...
```

By default, Anki will be launched using `QT_QPA_PLATFORM="vnc"`.  
This will enable Anki to be accessed using a VNC viewer, provided port `5900` is forwarded:  
![](images/vnc_gui.png)

## Building
To quickly build the image, issue:
```bash
docker build --progress=plain . -t headless-anki:test
```

Different versions of Anki and/or QT can be installed.  
Supply these versions as build flags:
```bash
docker build --build-arg ANKI_VERSION=23.12.1 --build-arg QT_VERSION=6 ...
```

For available versions, refer to [Ankis GitHub releases](https://github.com/ankitects/anki/releases).
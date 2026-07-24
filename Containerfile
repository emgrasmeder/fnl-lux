FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LUAROCKS_VERSION=3.13.0
ENV FENNEL_VERSION=1.6.1
# https://gitlab.com/andreyorst/deps.fnl/-/commit/cc143986bba3c3daa7629aa1f9d09bf73891f9f1
ENV DEPS_FNL_SHA=cc143986bba3c3daa7629aa1f9d09bf73891f9f1

RUN apt-get update && apt-get install -y \
    git \
    make \
    curl \
    ca-certificates \
    build-essential \
    unzip \
    lua5.4 \
    liblua5.4-dev \
    lua5.1 \
    liblua5.1-0-dev \
    xvfb \
    libgl1 \
    libopenal1 \
    libvorbis0a \
    libtheora0 \
    libmodplug1 \
    fuse \
    libfuse2t64 \
    && rm -rf /var/lib/apt/lists/*

# Love 11.5 Linux x86_64 AppImage (official release; no .deb for 11.5)
ENV LOVE_VERSION=11.5
RUN curl -fsSL -o /usr/local/bin/love-appimage \
    "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage" \
    && chmod +x /usr/local/bin/love-appimage \
    && printf '%s\n' '#!/bin/sh' 'exec /usr/local/bin/love-appimage --appimage-extract-and-run "$@"' > /usr/local/bin/love \
    && chmod +x /usr/local/bin/love

RUN curl -fsSL "https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz" \
    | tar xz -C /tmp \
    && cd "/tmp/luarocks-${LUAROCKS_VERSION}" \
    && ./configure --with-lua=/usr --lua-version=5.4 --prefix=/usr/local \
    && make \
    && make install \
    && rm -rf "/tmp/luarocks-${LUAROCKS_VERSION}"

RUN git clone --depth 1 --branch "${FENNEL_VERSION}" https://github.com/bakpakin/Fennel /tmp/fennel-src \
    && make -C /tmp/fennel-src fennel LUA=lua5.4 \
    && cp /tmp/fennel-src/fennel /usr/local/bin/fennel \
    && chmod +x /usr/local/bin/fennel \
    && rm -rf /tmp/fennel-src

RUN git clone https://gitlab.com/andreyorst/deps.fnl /tmp/deps.fnl \
    && cd /tmp/deps.fnl \
    && git checkout "${DEPS_FNL_SHA}" \
    && cp deps /usr/local/bin/deps \
    && chmod +x /usr/local/bin/deps \
    && rm -rf /tmp/deps.fnl

ENV PATH="/usr/local/bin:${PATH}"
WORKDIR /work

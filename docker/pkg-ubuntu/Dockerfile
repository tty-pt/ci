# syntax=docker/dockerfile:1
# Debian/Ubuntu builder image
FROM ubuntu:24.04

LABEL maintainer="repo@tty.pt"
LABEL description="Unified tty.pt builder for DEB packaging and APT repository publishing"

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    PACKAGER="tty.pt repo <repo@tty.pt>"

ARG UID=1001

# ------------------------------------------------------------
# 🔧 Ferramentas base
# ------------------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        git \
        make \
        gcc \
        g++ \
        fakeroot \
        dpkg-dev \
        debhelper \
        gnupg \
        gpg-agent \
        apt-utils \
        apt-transport-https \
        rsync \
        openssh-client \
        sudo \
        tar \
        gzip \
        xz-utils \
        bzip2 \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# 👤 Utilizador de build
# ------------------------------------------------------------
RUN useradd -m -u ${UID} builder && \
    mkdir -p /home/builder/.gnupg && \
    chmod 700 /home/builder/.gnupg && \
    echo "allow-loopback-pinentry" > /home/builder/.gnupg/gpg-agent.conf && \
    chown -R builder:builder /home/builder

# ------------------------------------------------------------
# ⚙️ Defaults e permissões
# ------------------------------------------------------------
RUN echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder && chmod 440 /etc/sudoers.d/builder

WORKDIR /home/builder

# ------------------------------------------------------------
# 🚀 Default user
# ------------------------------------------------------------
USER root

CMD ["/bin/bash"]

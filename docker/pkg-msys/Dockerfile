# syntax=docker/dockerfile:1.7
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL org.opencontainers.image.source="https://github.com/tty-pt"
LABEL description="Arch + MinGW64 builder otimizado para CI"

ARG UID=1001
ARG GID=1001
ARG PARALLEL_DL=14
ARG INCLUDE_WINE=1
ARG EXTRA_PKGS="mingw-w64-crt mingw-w64-headers mingw-w64-winpthreads binutils file"

ENV LANG=C.UTF-8 \
    MINGW_PREFIX=/usr/x86_64-w64-mingw32 \
    PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/lib/pkgconfig \
    MSYSTEM=MINGW64

# ---------- pacman.conf mínimo ----------
RUN set -eu; \
  sed -i 's/^#ParallelDownloads.*/ParallelDownloads = '"${PARALLEL_DL}"'/' /etc/pacman.conf || \
    echo "ParallelDownloads = ${PARALLEL_DL}" >> /etc/pacman.conf; \
  grep -q '^DisableDownloadTimeout' /etc/pacman.conf || echo 'DisableDownloadTimeout' >> /etc/pacman.conf; \
  grep -q '^\[multilib\]' /etc/pacman.conf || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf; \
  printf 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch\n' > /etc/pacman.d/mirrorlist

# ---------- Keyring (ORDEM CORRETA) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman-key --init && \
  pacman-key --populate archlinux && \
  pacman -Sy --noconfirm archlinux-keyring

# ---------- Base mínima ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -S --noconfirm --needed \
    base-devel git sudo curl gnupg openssh rsync tar gzip zstd \
    pacman-contrib zip wget unzip p7zip aria2 ${EXTRA_PKGS}

# ---------- Toolchain MinGW ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -S --noconfirm --needed mingw-w64-binutils mingw-w64-gcc

# ---------- Wine opcional ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  if [ "${INCLUDE_WINE}" = "1" ]; then \
    pacman -S --noconfirm --needed wine xorg-server-xvfb; \
  fi

# ---------- Limpeza ----------
RUN pacman -Scc --noconfirm && \
    rm -rf /usr/share/man/* /usr/share/doc/*

# ---------- Utilizador ----------
RUN groupadd -g ${GID} builder && \
    useradd -m -u ${UID} -g ${GID} builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/builder
USER root
CMD ["/bin/bash"]

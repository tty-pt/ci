# syntax=docker/dockerfile:1.7
# MinGW64 cross-compiler builder image for tty.pt
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL org.opencontainers.image.source="https://github.com/tty-pt"
LABEL description="Arch + MinGW64 cross-compiler builder for CI"

ARG UID=1001
ARG GID=1001
ARG PARALLEL_DL=14

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MINGW_PREFIX=/usr/x86_64-w64-mingw32 \
    PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/lib/pkgconfig \
    MSYSTEM=MINGW64 \
    PATH="/usr/x86_64-w64-mingw32/bin:$PATH" \
    MAKEFLAGS="-j$(nproc)"

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

# ---------- Base mínima (sem base-devel para evitar conflitos com mingw) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -Sy --noconfirm && \
  pacman -S --noconfirm --needed \
    base \
    git \
    sudo \
    curl \
    gnupg \
    openssh \
    rsync \
    tar \
    gzip \
    zstd \
    pacman-contrib \
    zip \
    wget \
    unzip \
    p7zip \
    aria2 \
    make \
    pkgconf \
    binutils \
    file

# ---------- Toolchain MinGW (garante overwrite dos arquivos de runtime) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -Sy --noconfirm && \
  pacman -S --noconfirm --needed \
    mingw-w64-binutils \
    mingw-w64-crt \
    mingw-w64-headers \
    mingw-w64-winpthreads && \
  pacman -S --noconfirm --needed --overwrite '/usr/lib/libgcc_s.so*' \
    --overwrite '/usr/lib/libstdc++.so*' \
    --overwrite '/usr/share/licenses/gcc-libs/RUNTIME.LIBRARY.EXCEPTION' \
    mingw-w64-gcc

# ---------- Limpeza ----------
RUN pacman -Scc --noconfirm && \
    rm -rf /usr/share/man/* /usr/share/doc/*

# ---------- Utilizador ----------
RUN groupadd -g ${GID} builder && \
    useradd -m -u ${UID} -g ${GID} builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder && \
    chmod 440 /etc/sudoers.d/builder && \
    mkdir -p /home/builder/.gnupg && \
    chmod 700 /home/builder/.gnupg && \
    chown -R builder:builder /home/builder

WORKDIR /home/builder
USER root
CMD ["/bin/bash"]

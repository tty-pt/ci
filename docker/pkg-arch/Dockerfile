# syntax=docker/dockerfile:1.7
# Arch builder & publisher image for tty.pt
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL org.opencontainers.image.source="https://github.com/tty-pt"
LABEL description="Unified Arch Linux image for building and publishing .pkg.tar.zst packages"

ARG PARALLEL_DL=10

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MAKEFLAGS="-j$(nproc)" \
    GPG_TTY=/dev/tty

# ---------- pacman.conf mínimo e estável ----------
RUN set -eu; \
  sed -i 's/^#ParallelDownloads.*/ParallelDownloads = '"${PARALLEL_DL}"'/' /etc/pacman.conf || \
    echo "ParallelDownloads = ${PARALLEL_DL}" >> /etc/pacman.conf; \
  grep -q '^DisableDownloadTimeout' /etc/pacman.conf || echo 'DisableDownloadTimeout' >> /etc/pacman.conf; \
  printf 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch\n' > /etc/pacman.d/mirrorlist

# ---------- Keyring (ordem correta) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman-key --init && \
  pacman-key --populate archlinux && \
  pacman -Sy --noconfirm archlinux-keyring

# ---------- Base build stack ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -S --noconfirm --needed \
      base-devel \
      pacman-contrib \
      gnupg \
      git \
      openssh \
      rsync \
      tar \
      gzip \
      zstd \
      curl \
      sudo && \
  pacman -Scc --noconfirm

# ---------- Limpeza ----------
RUN rm -rf /usr/share/man/* /usr/share/doc/*

# ---------- Utilizador builder (compatível com GitHub runners) ----------
RUN groupadd -g 1001 builder && \
    useradd -m -u 1001 -g 1001 builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder && \
    chmod 440 /etc/sudoers.d/builder && \
    mkdir -p /home/builder/.gnupg && \
    chmod 700 /home/builder/.gnupg && \
    chown -R builder:builder /home/builder

WORKDIR /home/builder

# Root por defeito (pacman / setup), mas pronto para sudo -u builder
USER root

CMD ["/bin/bash"]

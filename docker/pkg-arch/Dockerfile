# Arch builder & publisher image for tty.pt
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL description="Unified Arch Linux image for building and publishing .pkg.tar.zst packages"

ARG PARALLEL_DL=10

ENV LANG=C.UTF-8
ENV MAKEFLAGS="-j$(nproc)"
ENV GPG_TTY=/dev/tty

# ---------- pacman.conf mínimo e estável ----------
RUN set -eu; \
  sed -i 's/^#ParallelDownloads.*/ParallelDownloads = '"${PARALLEL_DL}"'/' /etc/pacman.conf || \
    echo "ParallelDownloads = ${PARALLEL_DL}" >> /etc/pacman.conf; \
  grep -q '^DisableDownloadTimeout' /etc/pacman.conf || echo 'DisableDownloadTimeout' >> /etc/pacman.conf; \
  printf 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch\n' > /etc/pacman.d/mirrorlist

# ---------- Keyring (ordem correta) ----------
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Sy --noconfirm archlinux-keyring

# ---------- Base build stack ----------
RUN pacman -S --noconfirm --needed \
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

# ---------- Utilizador builder (compatível com GitHub runners) ----------
RUN groupadd -g 1001 builder && \
    useradd -m -u 1001 -g 1001 builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/builder/.gnupg && \
    chmod 700 /home/builder/.gnupg && \
    chown -R builder:builder /home/builder

WORKDIR /home/builder

# Root por defeito (pacman / setup), mas pronto para sudo -u builder
USER root

CMD ["/bin/bash"]

# Arch builder & publisher image for tty.pt
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL description="Unified Arch Linux image for building and publishing .pkg.tar.zst packages"

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
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
      fakeroot \
      sudo && \
    pacman -Scc --noconfirm

# Criar utilizador 'builder' compatível com GitHub runners
RUN groupadd -g 1001 builder && \
    useradd -m -u 1001 -g 1001 builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    mkdir -p /home/builder/.gnupg && \
    chmod 700 /home/builder/.gnupg && \
    chown -R builder:builder /home/builder

ENV LANG=C.UTF-8
ENV MAKEFLAGS="-j$(nproc)"
ENV GPG_TTY=/dev/tty

WORKDIR /home/builder

# **Root by default** → pacman works normally
USER root

# Shell útil para debug ou para su builder
CMD ["/bin/bash"]

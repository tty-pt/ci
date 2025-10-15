# Start with a clean Arch base
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL description="Optimized MSYS2/MinGW64 image for building Windows .pkg.tar.zst packages"

RUN \
    # 1. Update mirrors and base system
    pacman -Syu --noconfirm --needed reflector && \
    reflector --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist && \
    pacman -Syyu --noconfirm && \
    pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -S --noconfirm archlinux-keyring && \
    \
    # 2. Enable [multilib]
    echo '[multilib]' >> /etc/pacman.conf && \
    echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf && \
    pacman -Syy && \
    \
    pacman -S --noconfirm --needed \
        base-devel \
        mingw-w64-binutils \
        mingw-w64-gcc \
        git \
        sudo \
        curl \
        gnupg \
        openssh \
        rsync \
        tar \
        gzip \
        zstd \
        pacman-contrib && \
    \
    # 4. Aggressively clean up in the same layer
    pacman -Scc --noconfirm && \
    rm -rf /usr/share/man/* /usr/share/doc/* /var/cache/pacman/pkg/*

# Create the 'builder' user for CI runs
RUN groupadd -g 1001 builder && \
    useradd -m -u 1001 -g 1001 builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R builder:builder /home/builder

# Configure the environment for MinGW
ENV LANG=C.UTF-8
ENV MINGW_PREFIX=/usr/x86_64-w64-mingw32
ENV PKG_CONFIG_PATH="/usr/x86_64-w64-mingw32/lib/pkgconfig"
ENV MSYSTEM=MINGW64

WORKDIR /home/builder
USER root
CMD ["/bin/bash"]

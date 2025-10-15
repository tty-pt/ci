# syntax=docker/dockerfile:1.7
FROM archlinux:latest

LABEL maintainer="repo@tty.pt"
LABEL org.opencontainers.image.source="https://github.com/tty-pt"
LABEL description="Arch + MinGW64 builder otimizado para CI (pacman paralelo, aria2, cache mounts, invalidações curtas)"

# ---------- Parâmetros ajustáveis ----------
ARG UID=1001
ARG GID=1001
ARG PARALLEL_DL=14          # pacman: ParallelDownloads
ARG ARIA_CONN=16            # aria2: conexões por ficheiro (-x)
ARG ARIA_SPLIT=16           # aria2: splits (-s)
ARG ARIA_CHUNK=1M           # aria2: chunk (-k)
ARG INCLUDE_WINE=0          # 1 para instalar wine
ARG EXTRA_PKGS=""           # pacotes extra (string)

ENV LANG=C.UTF-8 \
    MINGW_PREFIX=/usr/x86_64-w64-mingw32 \
    PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/lib/pkgconfig \
    MSYSTEM=MINGW64

# ---------- pacman.conf mínimo e mirrors estáveis ----------
# Usamos o geo.mirror oficial para não gastar tempo com reflector; paralelismo e XferCommand já aqui.
RUN set -eu; \
  sed -i 's/^#ParallelDownloads.*/ParallelDownloads = '"${PARALLEL_DL}"'/' /etc/pacman.conf || \
    echo 'ParallelDownloads = '"${PARALLEL_DL}"'' >> /etc/pacman.conf; \
  grep -q '^DisableDownloadTimeout' /etc/pacman.conf || echo 'DisableDownloadTimeout' >> /etc/pacman.conf; \
  grep -q '^\[multilib\]' /etc/pacman.conf || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf; \
  printf '## fast geo mirror\nServer = https://geo.mirror.pkgbuild.com/$repo/os/$arch\n' > /etc/pacman.d/mirrorlist; \
  # XferCommand com aria2 (multi-conexão real)
  grep -q '^XferCommand' /etc/pacman.conf || printf \
    '\nXferCommand = /usr/bin/aria2c -q -x%d -s%d -k%s --allow-overwrite=true --auto-file-renaming=false --dir /var/cache/pacman/pkg --out %%o %%u\n' \
    "${ARIA_CONN}" "${ARIA_SPLIT}" "${ARIA_CHUNK}" >> /etc/pacman.conf

# ---------- Keyring + base mínima (com cache BuildKit) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -Syyu --noconfirm --needed archlinux-keyring aria2 && \
  pacman-key --init && pacman-key --populate archlinux

# ---------- Ferramentas base (grupo) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -S --noconfirm --needed \
    base-devel git sudo curl gnupg openssh rsync tar gzip zstd pacman-contrib zip wget unzip p7zip ${EXTRA_PKGS}

# ---------- Toolchain MinGW separado para invalidar menos ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  pacman -S --noconfirm --needed mingw-w64-binutils mingw-w64-gcc

# ---------- Wine (opcional; não invalida toolchain) ----------
RUN --mount=type=cache,target=/var/lib/pacman/sync \
    --mount=type=cache,target=/var/cache/pacman/pkg \
  if [ "${INCLUDE_WINE}" = "1" ]; then pacman -S --noconfirm --needed wine xorg-server-xvfb; fi

# ---------- Limpeza (layers finais pequenos; caches BuildKit não entram na imagem) ----------
RUN pacman -Scc --noconfirm && rm -rf /usr/share/man/* /usr/share/doc/* /var/cache/pacman/pkg/*

# ---------- Utilizador builder ----------
RUN groupadd -g ${GID} builder && \
    useradd -m -u ${UID} -g ${GID} builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R builder:builder /home/builder

WORKDIR /home/builder
USER root
CMD ["/bin/bash"]

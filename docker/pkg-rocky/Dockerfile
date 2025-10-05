# Rocky Linux builder image
FROM rockylinux:9

LABEL maintainer="repo@tty.pt"
LABEL description="Unified tty.pt builder for RPM, APK and PACMAN packaging"

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    PACKAGER="tty.pt repo <repo@tty.pt>"

ARG UID=1001

# ------------------------------------------------------------
# 🔧 Ferramentas base
# ------------------------------------------------------------
RUN dnf -y update && \
    dnf -y install \
        git \
        make \
        gcc \
        rpm-build \
        rpm-sign \
        gnupg2 \
        createrepo_c \
        openssh-clients \
        rsync \
        tar \
        gzip \
        which \
        shadow-utils \
        zstd && \
    dnf clean all

# ------------------------------------------------------------
# 👤 Utilizador de build
# ------------------------------------------------------------
RUN useradd -m -u ${UID} builder && \
    mkdir -p /home/builder/.gnupg /home/builder/.abuild && \
    chmod 700 /home/builder/.gnupg /home/builder/.abuild && \
    chown -R builder:builder /home/builder && \
    mkdir -p /home/builder/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} && \
    echo "%_topdir %(echo $HOME)/rpmbuild" > /home/builder/.rpmmacros && \
    chown -R builder:builder /home/builder/rpmbuild

WORKDIR /home/builder

# ------------------------------------------------------------
# 🚀 Default user
# ------------------------------------------------------------
# Mantém builder criado, mas deixa o container correr como root por omissão.
# Assim o CI pode instalar pacotes sem sudo, mas localmente podes 'su builder'.
USER root

CMD ["/bin/bash"]

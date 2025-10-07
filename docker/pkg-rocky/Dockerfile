# Rocky Linux builder image
FROM rockylinux:9-minimal

LABEL maintainer="repo@tty.pt"
LABEL description="Unified tty.pt builder for RPM, APK and PACMAN packaging"

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm \
    PACKAGER="tty.pt repo <repo@tty.pt>"

ARG UID=1001


# Adiciona o repositório tty.pt
RUN cat > /etc/yum.repos.d/ttypt.repo <<'EOF'
[ttypt]
name=tty.pt repo
baseurl=https://tty.pt/rpm/$basearch
enabled=1
gpgcheck=0
priority=1
EOF


# Your repo + fallback to Rocky
RUN cat > /etc/yum.repos.d/ttypt.repo <<'EOF'
[ttypt]
name=tty.pt repo
baseurl=https://tty.pt/rpm/$basearch
enabled=1
gpgcheck=0
priority=1
EOF

# RUN cat > /etc/yum.repos.d/Rocky-BaseOS.repo <<'EOF'
# [baseos]
# name=Rocky Linux 9 - BaseOS
# baseurl=https://dl.rockylinux.org/pub/rocky/9/BaseOS/$basearch/os/
# gpgcheck=0
# enabled=1
# EOF

# RUN cat > /etc/yum.repos.d/Rocky-AppStream.repo <<'EOF'
# [appstream]
# name=Rocky Linux 9 - AppStream
# baseurl=https://dl.rockylinux.org/pub/rocky/9/AppStream/$basearch/os/
# gpgcheck=0
# enabled=1
# EOF

RUN cat > /etc/yum.repos.d/Rocky-CRB.repo <<'EOF'
[crb]
name=Rocky Linux 9 - CodeReady Builder
baseurl=https://dl.rockylinux.org/pub/rocky/9/CRB/$basearch/os/
gpgcheck=0
enabled=1
EOF

# ------------------------------------------------------------
# 🔧 Ferramentas base
# ------------------------------------------------------------

RUN microdnf -y makecache && \
    microdnf -y update && \
    microdnf -y install \
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
    microdnf clean all && \
    useradd -m -u ${UID} builder && \
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

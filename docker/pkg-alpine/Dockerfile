# Alpine builder & publisher image for tty.pt
FROM alpine:latest

LABEL maintainer="repo@tty.pt"
LABEL description="Unified Alpine image for packaging (.apk) and publishing repositories"

RUN apk add --no-cache \
    alpine-sdk \
    abuild \
    apk-tools \
    git \
    tar \
    gzip \
    fakeroot \
    gnupg \
    shadow \
    doas \
    openssh-client \
    rsync \
    curl

# Cria utilizador builder compatível com GitHub runners
RUN addgroup -g 1001 builder && adduser -D -u 1001 -G builder builder && \
    addgroup builder abuild && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /home/builder/.abuild /etc/apk/keys && \
    chown -R builder:builder /home/builder

ENV PACKAGER="tty.pt repo <repo@tty.pt>" \
    PACKAGER_PRIVKEY="/home/builder/.abuild/ttypt.rsa" \
    LANG=C.UTF-8

WORKDIR /home/builder

# Mantém root como default
USER root

# Por defeito, entra como builder (útil em execs interativos)
CMD ["su", "-", "builder"]

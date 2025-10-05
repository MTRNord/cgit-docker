ARG DEBIAN_VERSION=bookworm
ARG CGIT_VERSION=09d24d7cd0b7e85633f2f43808b12871bb209d69
ARG NGINX_VERSION=1.29.1

FROM debian:${DEBIAN_VERSION} AS build
ARG CGIT_VERSION

# To avoid conflict: undeclared REG_STARTEND compiling git with musl
# https://github.com/git/git/blob/23b219f8e3f2adfb0441e135f0a880e6124f766c/git-compat-util.h#L1279-L1281
ENV NO_REGEX=NeedsStartEnd

RUN apt-get update && apt-get install -y \
    git \
    make \
    gcc \
    libc6-dev \
    libssl-dev \
    zlib1g-dev \
    libluajit-5.1-dev \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt/cgit-repo
RUN git clone https://git.zx2c4.com/cgit . \
 && git checkout ${CGIT_VERSION} \
 && git submodule update --init --recursive

COPY ["cgit_build.conf", "/opt/cgit-repo/cgit.conf"]
RUN make && make install


FROM nginx:${NGINX_VERSION}-bookworm


# mailcap - provides /etc/mime.types
RUN apt-get update && apt-get install -y \
    fcgiwrap \
    git \
    git-daemon-sysvinit \
    groff \
    python3 \
    python3-pip \
    python3-pygments \
    python3-markdown \
    libluajit-5.1-2 \
    lua-http \
    mime-support \
    gitolite3 \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf python3 /usr/bin/python \
    && python3 -m pip install --break-system-packages rst2html

# Configure git user for Gitolite (user already created by gitolite3 package)
RUN mkdir -p /var/lib/gitolite3/.ssh \
    && chown -R gitolite3:gitolite3 /var/lib/gitolite3 \
    && chmod 700 /var/lib/gitolite3/.ssh \
    && ln -s /var/lib/gitolite3 /var/lib/git

# Setup SSH
RUN mkdir -p /run/sshd \
    && ssh-keygen -A

ENV CGIT_APP_USER=nginx

COPY ./rootfs/ /
COPY --from=build /opt/cgit /opt/cgit

EXPOSE 8080 2222
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD wget -qO- http://localhost:8080/healthz || exit 1

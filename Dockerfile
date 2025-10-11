ARG DEBIAN_VERSION=trixie
ARG CGIT_VERSION=724e902ac72b69c47292fa8e5b01df2ae9c6d936
ARG NGINX_VERSION=1.29.2

FROM debian:${DEBIAN_VERSION} AS build
ARG CGIT_VERSION

# To avoid conflict: undeclared REG_STARTEND compiling git with musl
# https://github.com/git/git/blob/23b219f8e3f2adfb0441e135f0a880e6124f766c/git-compat-util.h#L1279-L1281
ENV NO_REGEX=NeedsStartEnd

RUN apt-get update && apt-get install -y \
    git \
    make \
    gcc \
    g++ \
    libc6-dev \
    libssl-dev \
    zlib1g-dev \
    libluajit-5.1-dev \
    cmake \
    pkg-config \
    ninja-build \
    libgit2-dev \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt/cgit-repo
RUN git clone https://git.midnightthoughts.space/cgit . \
 && git checkout ${CGIT_VERSION} \
 && git submodule update --init --recursive

COPY ["cgit_build.conf", "/opt/cgit-repo/cgit.conf"]
RUN cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cgit && \
    cmake --build build --target install


FROM nginx:${NGINX_VERSION}-trixie


# mailcap - provides /etc/mime.types
# Pre-configure gitolite3 to skip interactive setup (we'll configure it via entrypoint script)
RUN echo 'gitolite3 gitolite3/adminkey string' | debconf-set-selections \
    && apt-get update && apt-get install -y \
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
    curl \
    nano \
    wget \
    libgit2-1.9 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf python3 /usr/bin/python \
    && python3 -m pip install --break-system-packages rst2html \
    && if ! getent passwd gitolite3 >/dev/null; then \
        adduser --quiet --system --home /var/lib/gitolite3 --shell /bin/bash \
            --no-create-home --gecos 'git repository hosting' \
            --group gitolite3; \
    fi \
    && mkdir -p /var/lib/gitolite3/.ssh /etc/gitolite3 \
    && chown -R gitolite3:gitolite3 /var/lib/gitolite3 \
    && chmod 700 /var/lib/gitolite3/.ssh \
    && ln -s /var/lib/gitolite3 /var/lib/git \
    && useradd -d /var/lib/gitolite3 -s /bin/bash -g gitolite3 -o -u $(id -u gitolite3) git

# Setup SSH
RUN mkdir -p /run/sshd \
    && ssh-keygen -A

# Configure global git settings
RUN git config --system init.defaultBranch main \
    && git config --system pull.rebase true \
    && git config --system core.autocrlf input \
    && git config --system merge.conflictStyle zdiff3 \
    && git config --system column.ui auto \
    && git config --system diff.algorithm histogram \
    && git config --system diff.colorMoved plain \
    && git config --system diff.mnemonicPrefix true \
    && git config --system diff.renames true \
    && git config --system branch.sort -committerdate \
    && git config --system rebase.autosquash true \
    && git config --system rebase.autostash true \
    && git config --system rebase.updateRefs true \
    && git config --system rerere.enabled true \
    && git config --system rerere.autoupdate true \
    && git config --system help.autocorrect prompt \
    && git config --system receive.fsckObjects true

ENV CGIT_APP_USER=gitolite3

COPY ./rootfs/ /
COPY --from=build /opt/cgit /opt/cgit

EXPOSE 8080 2222
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD wget -qO- http://localhost:8080/healthz || exit 1

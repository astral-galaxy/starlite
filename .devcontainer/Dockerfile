FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

LABEL maintainer="Celeste Peláez <celeste@etheryal.net>"
LABEL dev.containers.features="common"

ARG VARIANT=noble

# Control these if you need to change the values in the 'devcontainer.json'
# file in the directory. They have matching values.
ARG USERNAME=vscode
ARG USERID=1000
ARG GROUPID=1000

ENV RUSTUP_HOME=/usr/local/rustup \
     CARGO_HOME=/usr/local/cargo \
     PATH=/usr/local/cargo/bin:$PATH \
     RUST_VERSION=nightly

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

RUN set -eux; \
     microdnf install  -y --nodocs \
     tar gcc make git cmake clang lldb vim procps openssh-clients gzip \
     ca-certificates gnupg tzdata llvm sudo; \
     microdnf clean all;

# Install Rust
RUN set -eux; \
     systemArch="$(uname -m)"; \
     case "${systemArch}" in \
          x86_64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='6aeece6993e902708983b209d04c0d1dbb14ebb405ddb87def578d41f920f56d' ;; \
          arm) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='3c4114923305f1cd3b96ce3454e9e549ad4aa7c07c03aec73d1a785e98388bed' ;; \
          aarch64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='1cffbf51e63e634c746f741de50649bbbcbd9dbe1de363c9ecef64e278dba2b2' ;; \
          i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='0a6bed6e9f21192a51f83977716466895706059afb880500ff1d0e751ada5237' ;; \
          ppc64le) rustArch='powerpc64le-unknown-linux-gnu'; rustupSha256='079430f58ad4da1d1f4f5f2f0bd321422373213246a93b3ddb53dad627f5aa38' ;; \
          s390x) rustArch='s390x-unknown-linux-gnu'; rustupSha256='e7f89da453c8ce5771c28279d1a01d5e83541d420695c74ec81a7ec5d287c51c' ;; \
          *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
     esac; \
     url="https://static.rust-lang.org/rustup/archive/1.27.1/${rustArch}/rustup-init"; \
     curl -LO "$url"; \
     echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
     chmod +x rustup-init; \
     ./rustup-init -y --no-modify-path --profile default --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
     rm rustup-init; \
     chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
     rustup --version; \
     cargo --version; \
     rustc --version;

# Install Just
RUN set -eux; \
     curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin;

RUN groupadd --gid ${GROUPID} ${USERNAME}; \
     useradd --gid ${GROUPID} --uid ${USERID} -p ${USERNAME}  \
     -s /bin/bash -m ${USERNAME} --groups wheel; \
     echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME}; \
     chmod 0440 /etc/sudoers.d/${USERNAME};

WORKDIR /home/${USERNAME}
USER ${USERNAME}
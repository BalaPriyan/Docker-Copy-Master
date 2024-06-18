# Start from Ubuntu latest
FROM ubuntu:latest

# Metadata
LABEL org.opencontainers.image.source="https://github.com/BalaPriyan/BP-ML"
LABEL org.opencontainers.image.description="Docker for BP-MLB on Ubuntu docker image"

# Set timezone
ENV TZ=Asia/Dhaka

# Installing basic packages
RUN apt-get update && apt-get upgrade -y && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    sudo python3-pip python3-wheel python3-dev busybox locales git lshw qbittorrent-nox \
    aria2 p7zip-full xz-utils curl pv jq ffmpeg parallel neofetch make g++ gcc automake zip unzip \
    autoconf speedtest-cli mediainfo bash tzdata libffi-dev python3-virtualenv dpkg cmake \
    nodejs npm bash-completion wget && \
    npm install -g localtunnel && \
    npm install -g kill-port && \
    sed -i -e "s/bin\/sh/bin\/bash/" /etc/passwd && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get clean

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install build tools
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    libtool libcurl4-openssl-dev libsodium-dev libc-ares-dev libsqlite3-dev libfreeimage-dev \
    swig libboost-all-dev zlib1g-dev libpq-dev clang ccache gettext gawk libcrypto++-dev \
    libjpeg-turbo8-dev && \
    apt-get clean

# Install Cloudflared Tunnel
ARG TARGETPLATFORM
RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  ARCH=amd64  ;; \
         "linux/arm64")  ARCH=arm64  ;; \
         "linux/arm/v7") ARCH=armhf  ;; \
    esac && \
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb -O cloudflared-linux-${ARCH}.deb && \
    dpkg -i --force-architecture cloudflared-linux-${ARCH}.deb && \
    rm cloudflared-linux-${ARCH}.deb

# Clone MegaSdkC++ repository, build and install Python bindings
RUN git clone https://github.com/meganz/sdk.git ~/home/sdk && \
    cd ~/home/sdk && \
    rm -rf .git && \
    ./autogen.sh && \
    ./configure CFLAGS='-fpermissive' CXXFLAGS='-fpermissive -std=c++14' CPPFLAGS='-fpermissive' CCFLAGS='-fpermissive' \
    --disable-silent-rules --enable-python --with-sodium --disable-examples --with-python3 && \
    make -j$(nproc --all) && \
    cd bindings/python && \
    python3 setup.py bdist_wheel && \
    cd dist && \
    ls && \
    pip3 install *.whl

# Install Python dependencies
COPY requirements.txt /usr/src/app/requirements.txt
RUN pip3 install -r /usr/src/app/requirements.txt && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# Set locale and language environment
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"
RUN echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile.d/locale.sh && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8

# Clean up
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* && \
    rm -rf /root/.cache/pip

# Set default command
CMD ["/bin/bash"]

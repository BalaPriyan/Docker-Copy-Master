# Use an official Ubuntu as a parent image
FROM ubuntu:latest

# Set metadata for the image
LABEL org.opencontainers.image.source="https://github.com/yourusername/your-repo"
LABEL org.opencontainers.image.description="Docker image for your application"

# Set environment variables
ENV TZ=Asia/Dhaka

# Update and install packages
RUN apt-get update && apt-get install -y \
    sudo \
    python3 \
    python3-pip \
    curl \
    wget \    # Install wget
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/app

# Copy your application code into the container
COPY . .

# Set permissions if necessary
RUN chmod -R 777 /usr/src/app && \
    chmod -R +x /usr/src/app && \
    chmod -R 705 /usr/src/app

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Installing Build Tools
RUN echo -e "\e[32m[INFO]: Installing Building tools.\e[0m" && \
    apt-get update && \
    apt-get install -y \
    libtool libcurl4-openssl-dev libsodium-dev libcares-dev libsqlite3-dev libfreeimage-dev \
    swig libboost-all-dev zlib1g-dev libpq-dev clang ccache gettext gawk libcrypto++-dev \
    libjpeg-turbo8-dev

# Installing Cloudflared Tunnel
RUN echo -e "\e[32m[INFO]: Installing Cloudflared Tunnel.\e[0m" && \
    case ${TARGETPLATFORM} in \
         "linux/amd64")  ARCH=amd64  ;; \
         "linux/arm64")  ARCH=arm64  ;; \
         "linux/arm/v7") ARCH=armhf  ;; \
    esac && \
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb -O cloudflared-linux-${ARCH}.deb && \
    dpkg -i --force-architecture cloudflared-linux-${ARCH}.deb

# Building and Installing MegaSdkC++
ENV PYTHONWARNINGS=ignore
RUN echo -e "\e[32m[INFO]: Building and Installing MegaSdkC++.\e[0m" && \
    git clone https://github.com/meganz/sdk.git ~/home/sdk && \
    cd ~/home/sdk && rm -rf .git && \
    ./autogen.sh && \
    ./configure CFLAGS='-fpermissive' CXXFLAGS='-fpermissive' CPPFLAGS='-fpermissive' CCFLAGS='-fpermissive' \
    --disable-silent-rules --enable-python --with-sodium --disable-examples --with-python3 && \
    make -j$(nproc --all) && \
    cd bindings/python/ && \
    python3 setup.py bdist_wheel && \
    cd dist && ls && \
    pip3 install *.whl

# Caching Pip Requirements
RUN echo -e "\e[32m[INFO]: Caching Pip Requirements.\e[0m" && \
    wget https://raw.githubusercontent.com/BalaPriyan/BP-ML/master/requirements.txt -O requirements.txt && \
    pip3 install -U -r requirements.txt

# Running Final Apt Update
RUN echo -e "\e[32m[INFO]: Running Final Apt Update.\e[0m" && \
    apt-get update && apt-get upgrade -y

# Setup Language Environments
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"
RUN echo 'export LC_ALL=en_US.UTF-8' >> /etc/profile.d/locale.sh && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    cp /usr/share/zoneinfo/Asia/Dhaka /etc/localtime && \
    rm -rf *

SHELL ["/bin/bash", "-c"]

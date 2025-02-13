# Use an official Debian base image
FROM debian:bullseye

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_VERSION=17
ENV PATH="/root/.cargo/bin:${PATH}"

# Update and install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    wget \
    curl \
    gnupg \
    software-properties-common \
    inotify-tools \
    build-essential \
    gcc \
    gcc-multilib \
    clang \
    uuid-runtime \
    jq \
    make \
    docker.io \
    lib32gcc-s1 \
    lib32stdc++6 \
    git \
    python3 \
    python3-pip \
    nasm \
    qemu-system-x86 \
    libssl-dev \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22.x and npm
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Install Java (17)
RUN apt-get update && apt-get install -y openjdk-${JAVA_VERSION}-jdk && \
    rm -rf /var/lib/apt/lists/*

# Install Rust and required toolchains
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    rustup install nightly && \
    rustup default nightly && \
    rustup target add wasm32-unknown-unknown && \
    rustup target add i686-unknown-linux-gnu

# Install wasm-opt
RUN wget https://github.com/WebAssembly/binaryen/releases/download/version_113/binaryen-version_113-x86_64-linux.tar.gz && \
    tar -xvzf binaryen-version_113-x86_64-linux.tar.gz && \
    mv binaryen-version_113/bin/* /usr/local/bin/ && \
    rm -rf binaryen-version_113*

# Set up Docker permissions
RUN if ! getent group docker > /dev/null; then groupadd docker; fi && \
    usermod -aG docker root

# Clone the AnuraOS repository
RUN git clone --recursive https://github.com/MercuryWorkshop/anuraOS /anuraOS

# Set working directory
WORKDIR /anuraOS

# Install Python dependencies (if required by the project)
RUN pip3 install -r requirements.txt || true

# Start the Docker daemon and build the Alpine rootfs
RUN dockerd & \
    sleep 5 && \
    make rootfs-alpine

# Build the project
RUN make all

# Expose the server port
EXPOSE 8000

# Start the Docker daemon and the server
CMD ["sh", "-c", "dockerd & sleep 5 && make server"]

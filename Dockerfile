# Use an official Linux base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    build-essential \
    gcc-multilib \
    clang \
    uuid-runtime \
    jq \
    openjdk-11-jdk \
    inotify-tools \
    npm \
    make \
    docker.io \
    lib32gcc-s1 \
    lib32stdc++6 \
    && apt-get clean

# Remove conflicting libnode-dev package and install Node.js 22
RUN apt-get remove -y libnode-dev && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup target add wasm32-unknown-unknown && \
    rustup target add i686-unknown-linux-gnu && \
    rustup install nightly && \
    rustup default nightly && \
    rustup target add wasm32-unknown-unknown && \
    rustup target add i686-unknown-linux-gnu

# Add Rust environment to PATH for all subsequent commands
ENV PATH="/root/.cargo/bin:${PATH}"

# Add the current user to the Docker group (only if it doesn't already exist)
RUN getent group docker || groupadd docker && usermod -aG docker root

# Clone the AnuraOS repository
RUN git clone -b v1.2 --recursive https://github.com/MercuryWorkshop/anuraOS.git /anuraOS
# Set the working directory
WORKDIR /anuraOS

# Build the project
RUN make all 

# Expose the port for the server
EXPOSE 8000

# Start the Docker daemon and open a shell for manual input
CMD /bin/bash

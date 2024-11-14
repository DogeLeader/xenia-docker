# Use the latest Debian base image
FROM debian:latest

# Set the environment variable for non-interactive apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install necessary packages
RUN apt-get update && \
    apt-get install -y \
    git \
    build-essential \
    clang \
    cmake \
    xvfb \
    libgtk-3-dev \
    libpthread-stubs0-dev \
    liblz4-dev \
    libx11-dev \
    libx11-xcb-dev \
    libvulkan-dev \
    libsdl2-dev \
    libiberty-dev \
    libunwind-dev \
    libc++-dev \
    libc++abi-dev \
    python3 \
    python3-pip \
    && pip3 install websockify \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone the necessary repositories
RUN git clone https://github.com/novnc/noVNC.git /noVNC && \
    git clone https://github.com/novnc/websockify.git /websockify && \
    git clone https://github.com/xenia-project/xenia.git /xenia

# Set working directory to xenia
WORKDIR /xenia

# Set up the project
RUN ./xb setup

# Run the build process
RUN ./xb build  # Use --config=release if needed

# Pull latest changes, rebase, and update submodules
RUN ./xb pull

# Run premake to generate project files
RUN ./xb premake

# Expose the noVNC port
EXPOSE 8080

# Add the start script directly into the Dockerfile
RUN echo '#!/bin/bash' > /run.sh && \
    echo 'Xvfb :99 -screen 0 1280x720x24 &' >> /run.sh && \
    echo 'export DISPLAY=:99' >> /run.sh && \
    echo '/websockify/run --web /noVNC 8080 localhost:5901 &' >> /run.sh && \
    echo '/xenia/build/bin/xenia --log_file=stdout /path/to/Default.xex' >> /run.sh && \
    echo 'wait' >> /run.sh && \
    chmod +x /run.sh

# Command to run the noVNC server with Xvfb
CMD ["/run.sh"]

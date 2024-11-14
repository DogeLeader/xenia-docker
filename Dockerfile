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
    llvm \
    lld \
    llvm-dev \
    clang-tools \
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
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone the necessary repositories
RUN git clone --recurse-submodules https://github.com/novnc/noVNC.git /noVNC && \
    git clone --recurse-submodules https://github.com/novnc/websockify.git /websockify && \
    git clone --recurse-submodules https://github.com/xenia-project/xenia.git /xenia

# Set working directory to xenia
WORKDIR /xenia

# Run the setup command; will fail if not set up properly.
RUN ./xb setup && ./xb pull

# Run the build process
RUN ./xb build --verbose || { echo "Build failed"; exit 1; }

# Run premake to generate project files
RUN ./xb premake || { echo "Premake failed"; exit 1; }

# Set up a Python virtual environment and install websockify
RUN python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install websockify

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

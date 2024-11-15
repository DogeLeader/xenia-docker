# Start from the latest Ubuntu image
FROM ubuntu:latest

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    clang \
    libgtk-3-dev \
    libpthread-stubs0-dev \
    liblz4-dev \
    libx11-dev \
    libx11-xcb-dev \
    libvulkan-dev \
    libsdl2-dev \
    libiberty-dev \
    libunwind-18-dev \
    libc++-dev \
    libc++abi-dev \
    xvfb \
    python3 \
    python3-venv \
    python3-pip \
    ninja-build \
    cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone the Xenia repository
RUN git clone --recurse-submodules https://github.com/xenia-project/xenia.git /xenia

# Set the working directory to Xenia
WORKDIR /xenia

# Setup xenia
RUN ./xb setup && \
    ./xb pull && \
    CXXFLAGS="-Wno-error=integer-overflow" ./xb build

# Clone noVNC and websockify
RUN git clone https://github.com/novnc/noVNC.git /noVNC && \
    git clone https://github.com/novnc/websockify.git /websockify

# Create and activate a virtual environment, then install noVNC requirements
WORKDIR /websockify
RUN python3 -m venv venv && \
    ./venv/bin/pip install -r requirements.txt

# You can also copy the requirements.txt to avoid needing to clone noVNC
# Work Directory for noVNC
WORKDIR /noVNC
RUN ln -s vnc.html index.html

# Add start_emulator.sh script
RUN echo '#!/bin/bash\n\
\n\
# Start X Virtual Framebuffer\n\
Xvfb :99 -screen 0 1920x1080x16 &\n\
\n\
# Set display for Xvfb\n\
export DISPLAY=:99\n\
\n\
# Start the xenia emulator (Main GUI)\n\
/xenia/build/xenia-app &\n\
\n\
# Start websockify (make sure to activate the venv)\n\
. /websockify/venv/bin/activate && /websockify/run -D --web=/noVNC 6080 localhost:5900\n\
\n\
# Keep the script running\n\
wait' > /start_emulator.sh

# Make the start script executable
RUN chmod +x /start_emulator.sh

# Expose necessary ports
EXPOSE 6080 5900

# Start xvfb and noVNC server by default
CMD ["/start_emulator.sh"]

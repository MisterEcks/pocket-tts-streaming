ARG BUILD_FROM=python:3.11-slim
FROM $BUILD_FROM

# Install system dependencies required for git and building packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install core Python packages
RUN pip3 install --no-cache-dir \
    torch --index-url https://download.pytorch.org/whl/cpu \
    numpy \
    wyoming \
    zeroconf \
    stream2sentence \
    watchdog

# Install Pocket TTS directly from the source repository
RUN pip3 install --no-cache-dir git+https://github.com/kyutai-labs/pocket-tts.git

WORKDIR /app

# Copy the application files into the container
COPY wyoming_server.py /app/
COPY run.sh /app/

# Make the startup script executable
RUN chmod a+x /app/run.sh

ENTRYPOINT [ "/app/run.sh" ]
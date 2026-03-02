FROM python:3.12-slim

# Install system dependencies for audio and ML
RUN apt-get update && apt-get install -y \
    ffmpeg libsndfile1 git \
    && rm -rf /var/lib/apt/lists/*

# 1. Use the FULL URL including /whl/cpu
RUN pip install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cpu \
    --extra-index-url https://pypi.org \
    torch

# 2. Install the remaining requirements
RUN pip install --no-cache-dir \
    wyoming>=1.8.0 \
    watchdog \
    zeroconf \
    stream2sentence \
    safetensors \
    numpy

# Install Pocket TTS directly from the source repository
RUN pip3 install --no-cache-dir git+https://github.com/kyutai-labs/pocket-tts.git

WORKDIR /app

# Copy the application files into the container
COPY wyoming_server.py /app/
COPY run.sh /app/

# Make the startup script executable
RUN chmod a+x /app/run.sh

ENTRYPOINT [ "/app/run.sh" ]

FROM ubuntu:22.04
RUN  apt-get update \
  && apt-get install -y wget \
  && rm -rf /var/lib/apt/lists/*

# Download the binary and store it in a temporary directory
RUN mkdir /tmp/bin && wget -O /tmp/bin/admin https://github.com/UnownHash/Dragonite-Public/releases/download/admin-v1.12.0/admin-linux-arm64

# Set executable rights for the binary
RUN chmod +x /tmp/bin/admin

# Set up the entrypoint to execute the binary
ENTRYPOINT ["/tmp/bin/admin"]
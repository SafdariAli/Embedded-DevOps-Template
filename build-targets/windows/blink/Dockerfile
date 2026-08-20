# Ubuntu 24.04 is intentionally pinned to closely match the GitHub Actions

FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        ninja-build \
        mingw-w64 \
    && rm -rf /var/lib/apt/lists/*
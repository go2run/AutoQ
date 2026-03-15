ARG TARGETPLATFORM=linux/amd64
FROM --platform=${TARGETPLATFORM} ubuntu:noble-minimal

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/workspace/AutoQ/build/cli:${PATH}"

SHELL ["/bin/bash", "-c"]

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    g++ \
    make \
    cmake \
    libboost-filesystem-dev \
    libboost-test-dev \
    libboost-regex-dev \
    python3 \
    texlive-latex-extra \
    texlive-latex-base \
    texlive-latex-recommended \
    libvips-tools

# Create workspace directory and copy source code
WORKDIR /workspace
COPY . AutoQ

# Build the project (visible in docker build output)
WORKDIR /workspace/AutoQ
RUN make 2>&1 | tee build.log

# Run unit tests to verify build
RUN make test 2>&1 | tee test.log

# Set default command to bash with a welcome message
CMD ["/bin/bash", "-c", "echo \"AutoQ container ready. Use 'run_benchmarks.sh' to run example benchmarks.\"; bash"]

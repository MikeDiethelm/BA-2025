FROM ubuntu:24.04

# --------------------------------------------------
# 1. System-Pakete für Build-Toolchain
# --------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    clang \
    libssl-dev \
    curl \
    git \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# 2. Rust + Cargo installieren (als root)
# --------------------------------------------------
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# --------------------------------------------------
# 3. Aiken einmal vorkompilieren
# --------------------------------------------------
RUN cargo install aiken --locked

# Symlink, damit aiken auch unter /usr/local/bin sichtbar ist
RUN ln -s /root/.cargo/bin/aiken /usr/local/bin/aiken

# --------------------------------------------------
# 4. Arbeitsverzeichnis
# --------------------------------------------------
WORKDIR /workspace

CMD ["bash"]

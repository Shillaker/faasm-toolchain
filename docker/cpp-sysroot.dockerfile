FROM faasm/llvm:10.0.1 as llvm

FROM faasm/grpc-root:0.0.12
ARG SYSROOT_VERSION

# Copy the toolchain in from the LLVM container
COPY --from=llvm /usr/local/faasm /usr/local/faasm

RUN apt install -y \
    autoconf \
    autotools-dev \
    libtool \
    python3-dev \
    python3-pip

# Get the code
WORKDIR /code
RUN git clone -b v${SYSROOT_VERSION} https://github.com/faasm/faasm-toolchain
WORKDIR /code/faasm-toolchain

# Update submodules (not LLVM)
RUN git submodule update --init -f third-party/eigen
RUN git submodule update --init -f third-party/faabric
RUN git submodule update --init -f third-party/faasm-clapack
RUN git submodule update --init -f third-party/libffi
RUN git submodule update --init -f third-party/wasi-libc

RUN pip3 install -r requirements.txt

# Install the faasmtools lib
RUN pip3 install .

# -----------------------------
# CPP EMULATOR
# -----------------------------

RUN inv eigen --native

RUN inv dev.cmake
RUN inv dev.cc emulator

# -----------------------------
# WASM LIBRARIES
# -----------------------------

# Install files
RUN inv install

# Build libraries
RUN inv libc

# Install eigen to wasm
RUN inv eigen

# Install libffi
RUN inv libffi

# Both static and shared clapack
RUN inv clapack
RUN inv clapack --clean --shared

# Install Faasm CPP wasm lib
RUN inv libfaasm

# Install Faabric OpenMP wasm lib
RUN inv libfaasmp --clean

# Install Faabric MPI lib
RUN inv libfaasmpi --clean

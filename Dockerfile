# Docker image for building AIC22 C++ client
# source code should be mounted to /src

FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    build-essential \
    autoconf \
    libtool \
    pkg-config \
    cmake 

# Install yaml-cpp
RUN git clone https://github.com/jbeder/yaml-cpp.git --branch yaml-cpp-0.6.0 \
    && cd yaml-cpp \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make install

# Install protobuf
RUN git clone --recurse-submodules -b v1.45.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc \
    && cd grpc/third_party/protobuf \
    && ./autogen.sh \  
    && ./configure \  
    && make -j $(( $(nproc) - 1 )) \
    && make install \
    && ldconfig  

# Install gRPC
RUN export MY_INSTALL_DIR=$HOME/.local \
    && mkdir -p $MY_INSTALL_DIR \
    && export PATH=$MY_INSTALL_DIR/bin:$PATH \
    && cd grpc \
    && mkdir -p cmake/build \
    && pushd cmake/build \
    && cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR \
      ../.. \
    && make -j $(( $(nproc) - 1 )) \
    && make install \
    && popd

# Clean up
RUN rm -rf yaml-cpp \
    && rm -rf grpc \
    && apt-get remove -y \
        git \
        build-essential \
        autoconf \
        libtool \
        pkg-config \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

CMD export PATH="/root/.local/bin":$PATH && cd /src && rm -rf build && ./build.sh

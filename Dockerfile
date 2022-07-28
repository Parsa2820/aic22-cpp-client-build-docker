# Docker image for building AIC22 C++ client
# source code should be mounted to /src

FROM ubuntu:22.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
    git \
    build-essential \
    autoconf \
    libtool \
    pkg-config

# Install protobuf
RUN git clone --recurse-submodules -b v1.45.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc \
    && cd grpc/third_party/protobuf \
    && ./autogen.sh \  
    && ./configure \  
    && make -j $(( $(nproc) - 1 )) \
    && make -j $(( $(nproc) - 1 )) check \
    && sudo make install \
    && sudo ldconfig  

# Install gRPC
RUN cd ../.. \
    && mkdir -p cmake/build \
    && pushd cmake/build \
    && cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR \
      ../.. \
    && make -j $(( $(nproc) - 1 )) \
    && make install \
    && popd

# Install yaml-cpp
RUN cd .. \
    && git clone https://github.com/jbeder/yaml-cpp.git --branch yaml-cpp-0.6.0 \
    && cd yaml-cpp \
    && mkdir build \
    && cd build \
    && cmake .. \
    && sudo make install

CMD cd /src && ./build.sh
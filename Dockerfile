# Dockerfile for OpenPose
# N.B. This uses Caffe with CUDA 8 and cuDNN 5.1
#
# Examples:
#  Build Docker Image
#    * build (using CUDA 8 and cuDNN 6 as defaults):
#      docker build . -t openpose:1.0
#    * build with CUDA 9 and cuDNN 7:
#      docker build . --build-arg cuda="9.0" --build-arg cudnn="7" -t openpose:1.0
#    * build with CUDA 9 and cuDNN 7 and only enable the first GPU:
#      docker build . --build-arg cuda="9.0" --build-arg cudnn="7" -e NVIDIA_VISIBLE_DEVICES=0 -t openpose:1.0
#   * run instance of an image
#     nvidia-docker run --rm -ti openpose:1.0
#

#### TODO figure out how to make this work with TF (as opposed to Caffe)

FROM ubuntu:16.04
LABEL maintainer "J. Duane Northcutt"
LABEL jduanen.version "0.2.0"

# enable nvidia-docker plugin
LABEL com.nvidia.volumes.needed="nvidia_driver"

# CUDA version: valid inputs include "9.0", "8.0", "7.5"
ARG cuda=8.0

# cuDNN version: valid inputs include "7", "6", "5"
ARG cudnn=6

ENV FW="caffe" \
  CUDA=$cuda \
  CUDNN=$cudnn

LABEL jduanen.cuda.version=${CUDA}
LABEL jduanen.cudnn.version=${CUDNN}
LABEL jduanen.framework=${FW}

# install dependencies
WORKDIR /
RUN apt-get update && apt-get install -y --no-install-recommends \
  wget \
  cmake \
  curl \
  build-essential \
  git \
  libatlas-base-dev \
  libboost-all-dev \
  libgflags-dev \
  libgoogle-glog-dev \
  libhdf5-serial-dev \
  libleveldb-dev \
  liblmdb-dev \
  libopencv-dev \
  libprotobuf-dev \
  libsnappy-dev \
  pkg-config \
  protobuf-compiler \
  python-dev \
  python-pip \
  software-properties-common \
  sudo \
  && \
  pip install --upgrade pip numpy protobuf

# get NVIDIA repos and keys
WORKDIR /root
RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
    apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
    echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" >> /etc/apt/sources.list.d/cuda.list && \
    echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" >> /etc/apt/sources.list.d/nvidia-ml.list

# install CUDA packages
COPY files/cuda_pkgs_${CUDA} /tmp/cuda_pkgs
RUN chmod +x /tmp/cuda_pkgs && bash -c /tmp/cuda_pkgs

# install cuDNN packages
COPY files/cudnn_pkgs_${CUDNN} /tmp/cudnn_pkgs
RUN chmod +x /tmp/cudnn_pkgs && bash -c /tmp/cudnn_pkgs

# config nvidia-container-runtime
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
ENV NVIDIA_VISIBLE_DEVICES=all \
  NVIDIA_DRIVER_CAPABILITIES="compute,utility" \
  NVIDIA_REQUIRE_CUDA="cuda>=${CUDA}"

# set up for sudo use (in scripts)
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

# clone openpose repo
WORKDIR /root
RUN git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose.git && \
  cd openpose && \
  git pull origin master

# install caffe
WORKDIR /root/openpose
RUN bash ./ubuntu/install_cmake.sh

# build openpose
##RUN ldconfig && \
##  bash ./ubuntu/install_caffe_and_openpose_if_cuda8.sh

##  cmake --clean-first --build ./build . && \
##  cd ./build/ && \
##  make -j`nproc`

# cleanup
RUN apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /tmp/pip && \
  rm -rf /root/.cache

# validate the installation
#### TODO

ENTRYPOINT ["/bin/bash"]

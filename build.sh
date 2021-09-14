#!/bin/bash

#
# --- TOOLCHAIN ---
#
# wget https://github.com/kdrag0n/proton-clang/archive/refs/tags/20210327.tar.gz
# tar -xzf 20210327.tar.gz
# rm -f 20210327.tar.gz
#
# --- TOOLCHAIN ---
#

export ARCH=arm64
export ANDROID_MAJOR_VERSION=r
export PATH="/home/ichibauer/kernelBuilding/toolchains/protoC/bin:$PATH"
export PLATFORM_VERSION=11
export KBUILD_BUILD_USER=$(whoami)
export KBUILD_BUILD_HOST=$(hostname)

make O=out distclean

clear

make O=out M21_defconfig
time make O=out -j$(nproc --all) 2>&1 | tee log.txt

cd /home/ichibauer/kernelBuilding/zippy
rm -f *.zip
rm -f Image
cp /home/ichibauer/kernelBuilding/optio/out/arch/arm64/boot/Image /home/ichibauer/kernelBuilding/zippy/
zip -r9 newKern.zip *

mv newKern.zip /home/ichibauer/kernelBuilding/feenal/

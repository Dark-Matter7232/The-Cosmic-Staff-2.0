#!/bin/bash

export ARCH=arm64
export ANDROID_MAJOR_VERSION=r
export PLATFORM_VERSION=11
export PATH="/home/ichibauer/kernelBuilding/toolchains/protoC/bin:$PATH"
export KBUILD_BUILD_USER=ichibauer
export KBUILD_BUILD_HOST=celenkBalap

make clean
make mrproper
make distclean

clear

make M21_defconfig
time make -j$(nproc)

mv arch/arm64/boot/Image arch/arm64/boot/stock.img-kernel
mv arch/arm64/boot/stock.img-kernel /home/ichibauer/kernelBuilding/imageyy/AIK-Linux/split_img/

cd /home/ichibauer/kernelBuilding/imageyy/AIK-Linux
bash repackimg.sh
mv image-new.img boot.img
tar -cf newKern.tar boot.img
mv newKern.tar /mnt/d/Downloads

rm -f boot.img
bash unpackimg.sh
rm -f split_img/stock.img-kernel

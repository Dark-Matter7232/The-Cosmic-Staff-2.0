#!/bin/bash

BUILD_DATE=$(date +"%m-%d-%Y")

TC_DIR="/tc/protoC/bin"
ZIP_DIR="/home/ichibauer/kernelBuilding/zippy"
IMG_DIR="/home/ichibauer/kernelBuilding/imageyy/AIK-Linux"
OUT_IMG_DIR="/home/ichibauer/kernelBuilding/optio/out/arch/arm64/boot"
FINAL_DIR="/home/ichibauer/kernelBuilding/feenal"

export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=r
export PATH=${TC_DIR}:$PATH
export PLATFORM_VERSION=11
export KBUILD_BUILD_USER=$(whoami)
export KBUILD_BUILD_HOST=$(hostname)

if [ -d $(pwd)/out ]
then
    read -p "Build clean (y/n)? " cleanOrNo
    echo " "
    if [[ $cleanOrNo == "y" || $cleanOrNo == "Y" ]]
    then
        make O=out distclean
    fi
fi

clear

make O=out M21_defconfig
time make O=out -j$(nproc --all) 2>&1 | tee log.txt

echo " "
read -p "Zip (1) or Image (2)? " selection
echo " "
read -p "Enter name (no spaces): " fileName
echo " "

KERNEL_FILE=${fileName}-${BUILD_DATE}

if [ $selection == "1" ]
then
    echo " "
    cd ${ZIP_DIR}
    rm -f *.zip
    rm -f Image
    printf "Optio-\n" | figlet > version
    printf "\n Build date: ${BUILD_DATE}\n" >> version
    mv ${OUT_IMG_DIR}/Image ${ZIP_DIR}
    zip -r9 ${KERNEL_FILE}.zip *
    mv ${KERNEL_FILE}.zip ${FINAL_DIR}
    
    echo " "
    read -p "Want to reboot to recovery (y/n)? " bootToRecovery

    if [[ $bootToRecovery == "y" || $bootToRecovery == "Y" ]]
    then
        cd ${FINAL_DIR}
        adb push ${KERNEL_FILE}.zip /sdcard/Download
        adb reboot recovery
    else
        echo " "
        echo "Zip can be found at ${FINAL_DIR}/${KERNEL_FILE}.zip"
        echo " "
    fi

elif [ $selection == "2" ]
then
    IMG_DEFAULT="stock"

    echo " "
    cd ${IMG_DIR}
    bash cleanup.sh
    bash unpackimg.sh
    mv ${OUT_IMG_DIR}/Image ${IMG_DIR}/split_img/
    rm -f split_img/${IMG_DEFAULT}.img-kernel
    mv split_img/Image split_img/${IMG_DEFAULT}.img-kernel
    bash repackimg.sh
    mv image-new.img ${KERNEL_FILE}.img
    mv ${KERNEL_FILE}.img ${FINAL_DIR}

    echo " "
    read -p "Want to flash directly to the phone (y/n)? " flashOrNO

    if [[ $flashOrNO == "y" || $flashOrNO == "Y" ]]
    then
        cd ${FINAL_DIR}
        adb reboot download
        echo " "
        echo "Booting into download mode . . . "
        sleep 7
        echo " "
        echo "Press Enter key to FLASH . . . "
        read
        echo "Press Enter key to FLASH . . . [2] "
        read
        sudo heimdall flash --BOOT ${KERNEL_FILE}.img
    else
        echo " "
        echo "Image can be found at ${FINAL_DIR}/${KERNEL_FILE}.img"
        echo " "
    fi

else
    echo " "
    echo "Uh oh . . . "
    echo " "
fi

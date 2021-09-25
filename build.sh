#!/bin/bash

BUILD_DATE=$(date +"%m-%d-%Y")

# Directory variables
TC_DIR="/tc/protoC/bin"							 # Toolchain/compiler directory
ZIP_DIR="/home/ichibauer/kernelBuilding/zippy"				 # AnyKernel3 directory
IMG_DIR="/home/ichibauer/kernelBuilding/imageyy/AIK-Linux"               # AIK directory
OUT_IMG_DIR="/home/ichibauer/kernelBuilding/optio/out/arch/arm64/boot"   # Raw/compiled Image directory
FINAL_DIR="/home/ichibauer/kernelBuilding/feenal"                        # Where flashable image/zip is stored 
PUSH_PHONE_DIR="/sdcard/Download"                                        # Preferred phone's directory where backup & zipped kernel image are stored

export ARCH=arm64
export SUBARCH=arm64
export ANDROID_MAJOR_VERSION=r
export PATH=${TC_DIR}:$PATH
export PLATFORM_VERSION=11
export KBUILD_BUILD_USER=$(whoami)
export KBUILD_BUILD_HOST=$(hostname)

exitScript()
{
    exit 1
}

backupKernel()
{
    BACKUP_NAME="boot"

    printf "\n"
    printf "> Backing up your previous kernel to ${PUSH_PHONE_DIR}/${BACKUP_NAME}.img now . . . \n"
    printf "\n"

    adb shell su -c dd if=/dev/block/by-name/boot of=${PUSH_PHONE_DIR}/${BACKUP_NAME}.img
}

checkImage()
{
    if [ -e ${OUT_IMG_DIR}/Image ]
    then
        printf "\n"
        printf "> Found raw Image/kernel at ${OUT_IMG_DIR}/Image\n"
        printf "\n"
    else
        printf "\n"
        printf "> Raw Image/kernel not found; see log.txt for details.\n"
        printf "\n"

        exitScript
    fi
}

packKernel()
{
    checkImage

    read -p "> Zip (1) or Image (2)? " selection

    if ! [[ $selection == "1" || $selection == "2" ]]
    then
        printf "\n"
        printf "> Invalid input.\n"
        printf "\n"

        exitScript
    fi

    printf "\n"
    read -p "> Enter name (no spaces): " fileName
    printf "\n"

    KERNEL_FILE=${fileName}-${BUILD_DATE}

    read -p "> [ROOTED DEVICES ONLY] Would you like to backup your previous kernel (y/n)? " backupKernelOrNo

    if [[ $backupKernelOrNo == "y" || $backupKernelOrNo == "Y" ]]
    then
        backupKernel
    fi

    if [ $selection == "1" ]
    then
        printf "\n"
        cd ${ZIP_DIR}

        rm -f *.zip
        rm -f Image

        printf "Optio-\n" | figlet > version
        printf "\n Build date: ${BUILD_DATE}\n" >> version

        mv ${OUT_IMG_DIR}/Image ${ZIP_DIR}
        zip -r9 ${KERNEL_FILE}.zip *
        mv ${KERNEL_FILE}.zip ${FINAL_DIR}
        
        printf "\n"
        read -p "> Want to reboot to recovery (y/n)? " bootToRecovery

        if [[ $bootToRecovery == "y" || $bootToRecovery == "Y" ]]
        then
            cd ${FINAL_DIR}
            printf "\n"
            adb push ${KERNEL_FILE}.zip ${PUSH_PHONE_DIR}
            printf "\n"
            adb reboot recovery
        else
            printf "\n"
            printf "> Zip can be found at ${FINAL_DIR}/${KERNEL_FILE}.zip\n"
            printf "\n"
        fi
    elif [ $selection == "2" ]
    then
        IMG_DEFAULT="stock"
        printf "\n"

        cd ${IMG_DIR}
        bash cleanup.sh
        bash unpackimg.sh

        mv ${OUT_IMG_DIR}/Image ${IMG_DIR}/split_img/
        rm -f split_img/${IMG_DEFAULT}.img-kernel
        mv split_img/Image split_img/${IMG_DEFAULT}.img-kernel

        bash repackimg.sh
        mv image-new.img ${KERNEL_FILE}.img
        mv ${KERNEL_FILE}.img ${FINAL_DIR}

        printf "\n"
        read -p "> Want to flash directly to the phone (y/n)? " flashOrNO

        if [[ $flashOrNO == "y" || $flashOrNO == "Y" ]]
        then
            cd ${FINAL_DIR}
            adb reboot download

            printf "\n"
            printf "> Booting into download mode . . . \n"

            sleep 7

            printf "\n"
            printf "> Press Enter key to FLASH . . . \n"
            read
            printf "> Press Enter key to FLASH . . . [2] \n"
            read

            sudo heimdall flash --BOOT ${KERNEL_FILE}.img
        else
            printf "\n"
            printf "> Image can be found at ${FINAL_DIR}/${KERNEL_FILE}.img\n"
            printf "\n"
        fi
    fi

   exitScript
}

compileKernel()
{
    DEVICE_DEFCONFIG="M21_defconfig"

    if [ -d $(pwd)/out ]
    then
        read -p "> Build clean (y/n)? " cleanOrNo
        printf "\n"
        if [[ $cleanOrNo == "y" || $cleanOrNo == "Y" ]]
        then
            make O=out distclean
        fi
    fi

    clear

    make O=out ${DEVICE_DEFCONFIG}
    time make O=out -j$(nproc --all) 2>&1 | tee log.txt

    packKernel
}

compileKernel

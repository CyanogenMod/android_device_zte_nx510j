#!/bin/bash

set -e

export VENDOR=zte
export DEVICE=nx510j

export RADIO_IMAGES="BTFM.bin emmc_appsboot.mbn hyp.mbn NON-HLOS.bin pmic.mbn rpm.mbn sbl1.mbn sdi.mbn splash.img tz.mbn"

function extract() {
    for FILE in `egrep -v '(^#|^$)' $1`; do
        OLDIFS=$IFS IFS=":" PARSING_ARRAY=($FILE) IFS=$OLDIFS
        FILE=`echo ${PARSING_ARRAY[0]} | sed -e "s/^-//g"`
        DEST=${PARSING_ARRAY[1]}
        if [ -z $DEST ]; then
            DEST=$FILE
        fi
        DIR=`dirname $FILE`
        if [ ! -d $2/$DIR ]; then
            mkdir -p $2/$DIR
        fi
        if [ "$SRC" = "adb" ]; then
            # Try CM target first
            adb pull /system/$DEST $2/$DEST
            # if file does not exist try OEM target
            if [ "$?" != "0" ]; then
                adb pull /system/$FILE $2/$DEST
            fi
        else
            cp $SRC/system/$FILE $2/$DEST
            # if file dot not exist try destination
            if [ "$?" != "0" ]
                then
                cp $SRC/system/$DEST $2/$DEST
            fi
        fi
    done
}

function extract_radio() {
    if [ ! -d $1 ]; then
        mkdir -p $1
    fi
    for FILE in $RADIO_IMAGES; do
	      cp $RADIO_SRC/$FILE $1/$FILE
    done
}

if [ $# -eq 0 ]; then
  SRC=adb
else
  if [ $# -eq 1 ]; then
    SRC=$1
  elif [ $# -eq 2 ]; then
    SRC=$1
    RADIO_SRC=$2
  else
    echo "$0: bad number of arguments"
    echo ""
    echo "usage: $0 [PATH_TO_EXPANDED_ROM (PATH_TO_EXPANDED_RADIO)]"
    echo ""
    echo "If PATH_TO_EXPANDED_ROM is not specified, blobs will be extracted from"
    echo "the device using adb pull."
    exit 1
  fi
fi

BASE=../../../vendor/$VENDOR/$DEVICE/proprietary
rm -rf $BASE/*

extract ../../$VENDOR/$DEVICE/proprietary-files.txt $BASE

if [ -n "$RADIO_SRC" ]; then
    BASE=../../../vendor/$VENDOR/$DEVICE/radio
    rm -rf $BASE/*
    extract_radio $BASE
fi

./setup-makefiles.sh

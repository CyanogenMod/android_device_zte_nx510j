# Copyright (C) 2014 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := device/zte/nx510j

DEVICE_PACKAGE_OVERLAYS := $(LOCAL_PATH)/overlay

# copy customized media_profiles and media_codecs xmls for 8994
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media_profiles.xml:system/etc/media_profiles.xml \
    $(LOCAL_PATH)/media_codecs.xml:system/etc/media_codecs.xml

# Audio configuration file
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio_policy.conf:system/etc/audio_policy.conf

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio_output_policy.conf:system/vendor/etc/audio_output_policy.conf \
    $(LOCAL_PATH)/audio_effects.conf:system/vendor/etc/audio_effects.conf \
    $(LOCAL_PATH)/mixer_paths.xml:system/etc/mixer_paths.xml \
    $(LOCAL_PATH)/mixer_paths_i2s.xml:system/etc/mixer_paths_i2s.xml \
    $(LOCAL_PATH)/aanc_tuning_mixer.txt:system/etc/aanc_tuning_mixer.txt \
    $(LOCAL_PATH)/audio_platform_info_i2s.xml:system/etc/audio_platform_info_i2s.xml \
    $(LOCAL_PATH)/sound_trigger_mixer_paths.xml:system/etc/sound_trigger_mixer_paths.xml \
    $(LOCAL_PATH)/sound_trigger_platform_info.xml:system/etc/sound_trigger_platform_info.xml \
    $(LOCAL_PATH)/audio_platform_info.xml:system/etc/audio_platform_info.xml

# Listen configuration file
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/listen_platform_info.xml:system/etc/listen_platform_info.xml

# MSM IRQ Balancer configuration file
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/msm_irqbalance.conf:system/vendor/etc/msm_irqbalance.conf \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:system/etc/permissions/android.hardware.sensor.barometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:system/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:system/etc/permissions/android.hardware.sensor.stepdetector.xml \
    frameworks/native/data/etc/android.hardware.sensor.ambient_temperature.xml:system/etc/permissions/android.hardware.sensor.ambient_temperature.xml \
    frameworks/native/data/etc/android.hardware.sensor.relative_humidity.xml:system/etc/permissions/android.hardware.sensor.relative_humidity.xml

# file that declares the MIFARE NFC constant
# Commands to migrate prefs from com.android.nfc3 to com.android.nfc
# NFC access control + feature files + configuration
PRODUCT_COPY_FILES += \
    packages/apps/Nfc/migrate_nfc.txt:system/etc/updatecmds/migrate_nfc.txt \
    frameworks/native/data/etc/com.nxp.mifare.xml:system/etc/permissions/com.nxp.mifare.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:system/etc/permissions/com.android.nfc_extras.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:system/etc/permissions/android.hardware.nfc.hce.xml

# WLAN driver configuration files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/WCNSS_cfg.dat:system/etc/firmware/wlan/qca_cld/WCNSS_cfg.dat \
    $(LOCAL_PATH)/WCNSS_qcom_cfg.ini:system/etc/wifi/WCNSS_qcom_cfg.ini \
    $(LOCAL_PATH)/WCNSS_qcom_wlan_nv.bin:system/etc/wifi/WCNSS_qcom_wlan_nv.bin

#FEATURE_OPENGLES_EXTENSION_PACK support string config file
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:system/etc/permissions/android.hardware.opengles.aep.xml

#HDMI CEC
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.hdmi.cec.xml:system/etc/permissions/android.hardware.hdmi.cec.xml

# Override heap growth limit due to high display density on device
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapgrowthlimit=256m
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

# default is nosdcard, S/W button enabled in resource
PRODUCT_CHARACTERISTICS := nosdcard
PRODUCT_AAPT_CONFIG += xlarge large

PRODUCT_PACKAGES += \
    wpa_supplicant \
    wpa_supplicant_overlay.conf \
    p2p_supplicant_overlay.conf

PRODUCT_PACKAGES += \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libqcompostprocbundle


#ANT+ stack
PRODUCT_PACKAGES += \
    AntHalService \
    libantradio \
    antradio_app

# Nfc
#PRODUCT_PACKAGES += \
#    libnfc-nci \
#    libnfc_nci_jni \
#    nfc_nci.msm8994 \
#    NfcNci \
#    Tag \
#    com.android.nfc_extras

PRODUCT_BOOT_JARS += \
    qcmediaplayer \
    qcom.fmradio \
    security-bridge

# SmartcardService, SIM1,SIM2,eSE1 not including eSE2,SD1 as default
ADDITIONAL_BUILD_PROPERTIES += persist.nfc.smartcard.config=SIM1,SIM2,eSE1

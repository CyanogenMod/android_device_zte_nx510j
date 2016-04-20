#
# Copyright (C) 2016 The CyanogenMod Project
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
#

# This contains the module build definitions for the hardware-specific
# components for this device.
#
# As much as possible, those components should be built unconditionally,
# with device-specific names to avoid collisions, to avoid device-specific
# bitrot and build breakages. Building a component unconditionally does
# *not* include it on all devices, so it is safe even with hardware-specific
# components.

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),nx510j)

#----------------------------------------------------------------------
# Radio image
#----------------------------------------------------------------------
ifeq ($(ADD_RADIO_FILES), true)
radio_dir := $(TOP)/vendor/zte/nx510j/radio
RADIO_FILES := $(shell cd $(radio_dir) ; ls)
$(foreach f, $(RADIO_FILES), \
    $(call add-radio-file,radio/$(f)))

TARGET_BOOTLOADER_EMMC_INTERNAL := $(radio_dir)/emmc_appsboot.mbn
$(TARGET_BOOTLOADER_EMMC_INTERNAL): $(TARGET_BOOTLOADER)

INSTALLED_RADIOIMAGE_TARGET += $(TARGET_BOOTLOADER_EMMC_INTERNAL)
$(call add-radio-file,$(radio_dir)/NON-HLOS.bin)
$(call add-radio-file,$(radio_dir)/BTFM.bin)
$(call add-radio-file,$(radio_dir)/rpm.mbn)
$(call add-radio-file,$(radio_dir)/sbl1.mbn)
$(call add-radio-file,$(radio_dir)/sdi.mbn)
$(call add-radio-file,$(radio_dir)/tz.mbn)
$(call add-radio-file,$(radio_dir)/hyp.mbn)
$(call add-radio-file,$(radio_dir)/pmic.mbn)
$(call add-radio-file,$(radio_dir)/splash.img)
endif

include $(call all-makefiles-under,$(LOCAL_PATH))

include $(CLEAR_VARS)

# Create a link for the WCNSS config file, which ends up as a writable
# version in /data/misc/wifi
$(shell mkdir -p $(TARGET_OUT)/etc/firmware/wlan/qca_cld; \
    ln -sf /system/etc/wifi/WCNSS_qcom_cfg.ini \
	    $(TARGET_OUT)/etc/firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini; \
    ln -sf /persist/wlan_mac.bin \
	    $(TARGET_OUT_ETC)/firmware/wlan/qca_cld/wlan_mac.bin)

endif

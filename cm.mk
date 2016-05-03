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

$(call inherit-product, device/zte/nx510j/full_nx510j.mk)

# Enhanced NFC
$(call inherit-product, vendor/cm/config/nfc_enhanced.mk)

# Inherit some common CM stuff.
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

PRODUCT_NAME := cm_nx510j
BOARD_VENDOR := nubia
TARGET_VENDOR := nubia
PRODUCT_DEVICE := nx510j

PRODUCT_GMS_CLIENTID_BASE := android-zte

TARGET_VENDOR_PRODUCT_NAME := NX510J
TARGET_VENDOR_DEVICE_NAME := NX510J
PRODUCT_BUILD_PROP_OVERRIDES += TARGET_DEVICE=NX510J PRODUCT_NAME=NX510J

## Use the latest approved GMS identifiers
ifneq ($(SIGN_BUILD),true)
PRODUCT_BUILD_PROP_OVERRIDES += \
    BUILD_FINGERPRINT=nubia/NX510J/NX510J:6.0.1/MMB29M/nubia04300425:user/release-keys \
    PRIVATE_BUILD_DESC="NX510J-user 6.0.1 MMB29M eng.nubia.20160430.042439 release-keys"
endif

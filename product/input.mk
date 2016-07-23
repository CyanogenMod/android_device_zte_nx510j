PRODUCT_PACKAGES += \
    init.nubia.tp.sh

# Input device files for nx510j
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/Generic.kl:system/usr/keylayout/Generic.kl \
    $(LOCAL_PATH)/configs/gpio-keys.kl:system/usr/keylayout/gpio-keys.kl \
    $(LOCAL_PATH)/configs/qpnp_pon.kl:system/usr/keylayout/qpnp_pon.kl

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

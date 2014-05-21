TARGET_USES_QCOM_BSP := true

$(call inherit-product, device/qcom/common/common.mk)

PRODUCT_NAME := plutonium
PRODUCT_DEVICE := plutonium

PRODUCT_BOOT_JARS += qcmediaplayer:WfdCommon:oem-services:qcom.fmradio:org.codeaurora.Performance

PRODUCT_PACKAGES += \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libqcompostprocbundle

# Feature definition files for plutonium
PRODUCT_COPY_FILES += \
    system/bluetooth/data/main.le.conf:system/etc/bluetooth/main.conf \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.barometer.xml:system/etc/permissions/android.hardware.sensor.barometer.xml

#battery_monitor
PRODUCT_PACKAGES += \
    battery_monitor \
    battery_shutdown

#fstab.qcom
PRODUCT_PACKAGES += fstab.qcom

#ANT stack
PRODUCT_PACKAGES += \
        AntHalService \
        libantradio \
        ANTRadioService \
        antradio_app

# Enable strict operation
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.strict_op_enable=false

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.whitelist=/system/etc/whitelist_appops.xml

PRODUCT_COPY_FILES += \
    device/qcom/plutonium/whitelist_appops.xml:system/etc/whitelist_appops.xml

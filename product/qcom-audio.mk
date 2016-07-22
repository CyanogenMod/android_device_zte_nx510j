PRODUCT_PACKAGES += \
    audiod \
    libqcompostprocbundle \
    libqcomvisualizer \
    libqcomvoiceprocessingdescriptors \
    libqcomvoiceprocessing

# speaker protection
PRODUCT_PROPERTY_OVERRIDES += \
    persist.speaker.prot.enable=false \
    persist.spkr.cal.duration=0

# surround sound recording
PRODUCT_PROPERTY_OVERRIDES += \
    ro.qc.sdk.audio.ssr=false \
    persist.audio.ssr.3mic=false

# offload settings
PRODUCT_PROPERTY_OVERRIDES += \
    audio.offload.gapless.enabled=true \
    audio.offload.buffer.size.kb=32 \
    audio.offload.video=true \
    audio.offload.pcm.16bit.enable=true \
    audio.offload.pcm.24bit.enable=true \
    audio.offload.multiple.enabled=false \
    audio.deep_buffer.media=true

# voip
PRODUCT_PROPERTY_OVERRIDES += \
    use.voice.path.for.pcm.voip=true

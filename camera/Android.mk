LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SHARED_LIBRARIES := liblog libcutils libgui libbinder libutils

LOCAL_SRC_FILES := \
    zte_camera.c

LOCAL_MODULE := libzte_camera
LOCAL_MODULE_CLASS := SHARED_LIBRARIES

include $(BUILD_SHARED_LIBRARY)

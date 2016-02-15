/*
 * Copyright (C) 2008 The Android Open Source Project
 * Copyright (C) 2014 The Linux Foundation. All rights reserved.
 * Copyright (C) 2015 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


// #define LOG_NDEBUG 0

#include <cutils/log.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>

#include <sys/ioctl.h>
#include <sys/types.h>

#include <hardware/lights.h>

/******************************************************************************/

#define MAX_PATH_SIZE 80

#define PM_PWM_LUT_LOOP			0x01
#define PM_PWM_LUT_RAMP_UP		0x02
#define PM_PWM_LUT_REVERSE		0x04
#define PM_PWM_LUT_PAUSE_HI_EN		0x08
#define PM_PWM_LUT_PAUSE_LO_EN		0x10

#define PM_PWM_LUT_NO_TABLE		0x20
#define PM_PWM_LUT_USE_RAW_VALUE	0x40

#define BREATH_LED_BRIGHTNESS_NOTIFICATION	"0,5,10,15,20,26,31,36,41,46,51,56,61,66,71,77,82,87,92,97,102,107,112,117,122,128,133,138,143,148,153,158,163,168,173,179,184,189,194,199,204,209,214,219,224,230,235,240,245,250,255"
#define BREATH_LED_BRIGHTNESS_BUTTONS		"0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60"
#define BREATH_LED_BRIGHTNESS_BATTERY		"0,50"
#define BREATH_LED_BRIGHTNESS_CHARGING		"20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60"

static pthread_once_t g_init = PTHREAD_ONCE_INIT;
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
static struct light_state_t g_notification;
static struct light_state_t g_battery;
static struct light_state_t g_buttons;
static struct light_state_t g_attention;

#define BREATH_SOURCE_NOTIFICATION	0x01
#define BREATH_SOURCE_BATTERY		0x02
#define BREATH_SOURCE_BUTTONS		0x04
#define BREATH_SOURCE_ATTENTION		0x08
#define BREATH_SOURCE_NONE		0xFF
static int active_states = 0;

static int last_state = BREATH_SOURCE_NONE;

static int g_breathing = 0;

static int initialized = 0;

char const*const LCD_FILE
        = "/sys/class/leds/lcd-backlight/brightness";

char const*const BREATH_LED_LUT_FLAGS
        = "/sys/class/leds/nubia_led/lut_flags";

char const*const BREATH_LED_PAUSE_HI
        = "/sys/class/leds/nubia_led/pause_hi";

char const*const BREATH_LED_PAUSE_LO
        = "/sys/class/leds/nubia_led/pause_lo";

char const*const BREATH_LED_RAMP_STEP_MS
        = "/sys/class/leds/nubia_led/ramp_step_ms";

char const*const BREATH_LED_DUTY_PCTS
        = "/sys/class/leds/nubia_led/duty_pcts";

char const*const BREATH_LED
        = "/sys/class/leds/nubia_led/brightness";

char const*const BREATH_LED_OUTN
        = "/sys/class/leds/nubia_led/outn";

char const*const BREATH_LED_BLINK_MODE
        = "/sys/class/leds/nubia_led/blink_mode";

char const*const BATTERY_CAPACITY
        = "/sys/class/power_supply/battery/capacity";

char const*const BATTERY_CHARGING_STATUS
        = "/sys/class/power_supply/battery/status";

char const*const KEYPAD_ENABLE
        = "/data/tp/keypad_enable";

/**
 * device methods
 */

void init_globals(void)
{
    // init the mutex
    pthread_mutex_init(&g_lock, NULL);
}

static int
write_int(char const* path, int value)
{
    int fd;
    static int already_warned = 0;

    fd = open(path, O_RDWR);
    if (fd >= 0) {
        char buffer[20];
        int bytes = snprintf(buffer, sizeof(buffer), "%d\n", value);
        ssize_t amt = write(fd, buffer, (size_t)bytes);
        close(fd);
        return amt == -1 ? -errno : 0;
    } else {
        if (already_warned == 0) {
            ALOGE("write_int failed to open %s\n", path);
            already_warned = 1;
        }
        return -errno;
    }
}

static int
read_int(char const* path, int *value)
{
    int fd;
    static int already_warned = 0;

    fd = open(path, O_RDONLY);
    if (fd >= 0) {
        char buffer[20];
        int amt = read(fd, buffer, 20);
        sscanf(buffer, "%d\n", value);
        close(fd);
        return amt == -1 ? -errno : 0;
    } else {
        if (already_warned == 0) {
            ALOGD("read_int failed to open %s\n", path);
            already_warned = 1;
        }
        return -errno;
    }
}

static int
write_str(char const* path, char *value)
{
    int fd;
    static int already_warned = 0;

    fd = open(path, O_RDWR);
    if (fd >= 0) {
        char buffer[PAGE_SIZE];
        int bytes = sprintf(buffer, "%s\n", value);
        int amt = write(fd, buffer, bytes);
        close(fd);
        return amt == -1 ? -errno : 0;
    } else {
        if (already_warned == 0) {
            ALOGD("write_str failed to open %s\n", path);
            already_warned = 1;
        }
        return -errno;
    }
}

static int
is_lit(struct light_state_t const* state)
{
    return state->color & 0x00ffffff;
}

static int
rgb_to_brightness(struct light_state_t const* state)
{
    int color = state->color & 0x00ffffff;
    return ((77*((color>>16)&0x00ff))
            + (150*((color>>8)&0x00ff)) + (29*(color&0x00ff))) >> 8;
}

static int
set_light_backlight(struct light_device_t* dev,
        struct light_state_t const* state)
{
    int err = 0;
    if (!dev) {
        return -1;
    }
    int brightness = rgb_to_brightness(state);
    pthread_mutex_lock(&g_lock);
    err = write_int(LCD_FILE, brightness);
    pthread_mutex_unlock(&g_lock);
    return err;
}

static int
set_breath_light_locked(int event_source,
	struct light_state_t const* state)
{
    int len;
    int blink;
    int onMS, offMS, ramp;
    unsigned int colorRGB, event_colorRGB;
    int brightness;

    event_colorRGB = state->color;

    brightness = rgb_to_brightness(state);

    if (brightness > 0) {
        active_states |= event_source;
    } else {
        active_states &= ~event_source;
        if (active_states == 0) {
            ALOGV("disabling buttons backlight\n");
            write_int(BREATH_LED_LUT_FLAGS, (int)PM_PWM_LUT_NO_TABLE); // smoothly turn led off
            last_state = BREATH_SOURCE_NONE;
            return 0;
        }
    }

    if (last_state < event_source) {
        return 0;
    }

    colorRGB = state->color;

    switch (state->flashMode) {
        case LIGHT_FLASH_TIMED:
            onMS = state->flashOnMS;
            offMS = state->flashOffMS;
            break;
        case LIGHT_FLASH_NONE:
        default:
            onMS = 0;
            offMS = 0;
            break;
    }

    blink = (onMS+offMS)?1:0;

    char* light_template;
    int lut_flags = 0;
    if (active_states & BREATH_SOURCE_NOTIFICATION) {
        state = &g_notification;
        light_template = BREATH_LED_BRIGHTNESS_NOTIFICATION;
        lut_flags = PM_PWM_LUT_RAMP_UP;
        if (blink) {
            lut_flags |= PM_PWM_LUT_LOOP|PM_PWM_LUT_REVERSE|PM_PWM_LUT_PAUSE_HI_EN|PM_PWM_LUT_PAUSE_LO_EN;
        }
        last_state = BREATH_SOURCE_NOTIFICATION;
    } else if (active_states & BREATH_SOURCE_BATTERY) {
        state = &g_battery;
        // can't get battery info from state, getting it from sysfs
        int is_charging = 0;
        int capacity = 0;
        char charging_status[15];
        FILE* fp = fopen(BATTERY_CHARGING_STATUS, "rb");
        fgets(charging_status, 14, fp);
        fclose(fp);
        if (strstr(charging_status, "Discharging") != NULL)
            is_charging = 0;
        else
            is_charging = 1;
        read_int(BATTERY_CAPACITY, &capacity);
        if (is_charging == 0) {
            // battery low
            light_template = BREATH_LED_BRIGHTNESS_BATTERY;
            lut_flags = PM_PWM_LUT_LOOP|PM_PWM_LUT_RAMP_UP|PM_PWM_LUT_REVERSE|PM_PWM_LUT_PAUSE_HI_EN|PM_PWM_LUT_PAUSE_LO_EN;
            onMS = 300;
            offMS = 1500;
        } else {
            if (capacity < 90) { // see batteryService.java:978
                // battery chagring
                light_template = BREATH_LED_BRIGHTNESS_CHARGING;
                lut_flags = PM_PWM_LUT_LOOP|PM_PWM_LUT_RAMP_UP|PM_PWM_LUT_REVERSE|PM_PWM_LUT_PAUSE_HI_EN|PM_PWM_LUT_PAUSE_LO_EN;
                onMS = 500;
                offMS = 500;
            } else {
                // battery full
                light_template = BREATH_LED_BRIGHTNESS_CHARGING;
                lut_flags = PM_PWM_LUT_RAMP_UP;
                onMS = 0;
                offMS = 0;
            }
        }
        last_state = BREATH_SOURCE_BATTERY;
    } else if (active_states & BREATH_SOURCE_BUTTONS) {
        if (last_state == BREATH_SOURCE_BUTTONS) {
            return 0;
        }
        state = &g_buttons;
        light_template = BREATH_LED_BRIGHTNESS_BUTTONS;
        lut_flags = PM_PWM_LUT_RAMP_UP;
        last_state = BREATH_SOURCE_BUTTONS;
    } else {
        last_state = BREATH_SOURCE_NONE;
        ALOGD("Unknown state");
        return 0;
    }

    if (!initialized) {
        initialized = 1;
        write_int(BREATH_LED_OUTN, (int)8);
        write_int(BREATH_LED_BLINK_MODE, (int)6);
        write_int(BREATH_LED, (int)255);
    }

    ALOGV("writing values: pause_lo=%d, pause_hi=%d, lut_flags=%d\n", offMS, onMS, lut_flags);
    write_str(BREATH_LED_DUTY_PCTS, light_template);
    write_int(BREATH_LED_RAMP_STEP_MS, (int)20);
    if (offMS > 0)
        write_int(BREATH_LED_PAUSE_LO, (int)offMS);
    if (onMS > 0)
        write_int(BREATH_LED_PAUSE_HI, (int)onMS);
    write_int(BREATH_LED_LUT_FLAGS, lut_flags);

    return 0;
}

static int
set_light_battery(struct light_device_t* dev,
        struct light_state_t const* state)
{
    if (!dev) {
        return -1;
    }
    pthread_mutex_lock(&g_lock);
    g_battery = *state;
    set_breath_light_locked(BREATH_SOURCE_BATTERY, &g_battery);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int
set_light_notifications(struct light_device_t* dev,
        struct light_state_t const* state)
{
    if (!dev) {
        return -1;
    }
    pthread_mutex_lock(&g_lock);
    g_notification = *state;
    set_breath_light_locked(BREATH_SOURCE_NOTIFICATION, &g_notification);
    pthread_mutex_unlock(&g_lock);
    return 0;
}

static int
set_light_buttons(struct light_device_t* dev,
        struct light_state_t const* state)
{
    int err = 0;
    int brightness = rgb_to_brightness(state);
    bool keypad_enable;
    FILE* fp;
    if (!dev) {
        return -1;
    }
    fp = fopen(KEYPAD_ENABLE, "rb");
    fscanf(fp, "%d", &keypad_enable)
    fclose(fp);
    pthread_mutex_lock(&g_lock);
    g_buttons = *state;
    if (brightness && keypad_enable)
        err = write_int(BREATH_LED_BLINK_MODE, 6);
    else
        err = write_int(BREATH_LED_BLINK_MODE, 2);
    err = set_breath_light_locked(BREATH_SOURCE_BUTTONS, &g_buttons);
    pthread_mutex_unlock(&g_lock);
    return err;
}

/** Close the lights device */
static int
close_lights(struct light_device_t *dev)
{
    if (dev) {
        free(dev);
    }
    return 0;
}


/******************************************************************************/

/**
 * module methods
 */

/** Open a new instance of a lights device using name */
static int open_lights(const struct hw_module_t* module, char const* name,
        struct hw_device_t** device)
{
    int (*set_light)(struct light_device_t* dev,
            struct light_state_t const* state);

    if (0 == strcmp(LIGHT_ID_BACKLIGHT, name))
        set_light = set_light_backlight;
    else if (0 == strcmp(LIGHT_ID_BATTERY, name))
        set_light = set_light_battery;
    else if (0 == strcmp(LIGHT_ID_NOTIFICATIONS, name))
        set_light = set_light_notifications;
    else if (0 == strcmp(LIGHT_ID_BUTTONS, name))
        set_light = set_light_buttons;
    else
        return -EINVAL;

    pthread_once(&g_init, init_globals);

    struct light_device_t *dev = malloc(sizeof(struct light_device_t));

    if (!dev)
        return -ENOMEM;

    memset(dev, 0, sizeof(*dev));

    dev->common.tag = HARDWARE_DEVICE_TAG;
    dev->common.version = 0;
    dev->common.module = (struct hw_module_t*)module;
    dev->common.close = (int (*)(struct hw_device_t*))close_lights;
    dev->set_light = set_light;

    *device = (struct hw_device_t*)dev;
    return 0;
}

static struct hw_module_methods_t lights_module_methods = {
    .open =  open_lights,
};

/*
 * The lights Module
 */
struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .version_major = 1,
    .version_minor = 0,
    .id = LIGHTS_HARDWARE_MODULE_ID,
    .name = "Nubia Z9 Max lights Module",
    .author = "Google, Inc., dianlujitao, proDOOMman",
    .methods = &lights_module_methods,
};

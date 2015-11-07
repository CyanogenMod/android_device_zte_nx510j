/*
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

package com.cyanogenmod.settings.device;

import android.app.ActivityManagerNative;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Message;
import android.os.PowerManager;
import android.os.SystemClock;
import android.text.TextUtils;
import android.view.KeyEvent;

import com.android.internal.os.DeviceKeyHandler;
import com.android.internal.widget.LockPatternUtils;

public class KeyHandler implements DeviceKeyHandler {

    private static final String TAG = KeyHandler.class.getSimpleName();
    private static final int GESTURE_REQUEST = 1;

    // Supported scancodes
    private static final int KEY_DOUBLE_TAP = 68;

    private Intent mPendingIntent;
    private LockPatternUtils mLockPatternUtils;
    private final Context mContext;
    private final PowerManager mPowerManager;
    private EventHandler mEventHandler;
    private SensorManager mSensorManager;
    private Sensor mProximitySensor;

    public KeyHandler(Context context) {
        mContext = context;
        mPowerManager = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
        mLockPatternUtils = new LockPatternUtils(context);

        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_USER_PRESENT);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        context.registerReceiver(mReceiver, filter);
        mEventHandler = new EventHandler();
        mSensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        mProximitySensor = mSensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY);
    }

    private BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (intent == null) {
                return;
            }
            String action = intent.getAction();
            if (TextUtils.equals(action, Intent.ACTION_USER_PRESENT)) {
                if (mPendingIntent != null) {
                    try {
                        mContext.startActivity(mPendingIntent);
                    } catch (ActivityNotFoundException e) {
                    }
                    mPendingIntent = null;
                }
            } else if (TextUtils.equals(action, Intent.ACTION_SCREEN_OFF)) {
                mPendingIntent = null;
            }
        }
    };

    private class EventHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
            KeyEvent event = (KeyEvent) msg.obj;
            if (event.getScanCode() == KEY_DOUBLE_TAP && !mPowerManager.isScreenOn()) {
                mPowerManager.wakeUp(SystemClock.uptimeMillis());
            }
        }
    }

    public boolean handleKeyEvent(KeyEvent event) {
        if (event.getAction() != KeyEvent.ACTION_UP) {
            return false;
        }
        boolean isKeySupported = (event.getScanCode() == KEY_DOUBLE_TAP);
        if (isKeySupported && !mEventHandler.hasMessages(GESTURE_REQUEST)) {
            Message msg = getMessageForKeyEvent(event);
            if (mProximitySensor != null) {
                mEventHandler.sendMessageDelayed(msg, 200);
                processEvent(event);
            } else {
                mEventHandler.sendMessage(msg);
            }
        }
        return isKeySupported;
    }

    private Message getMessageForKeyEvent(KeyEvent keyEvent) {
        Message msg = mEventHandler.obtainMessage(GESTURE_REQUEST);
        msg.obj = keyEvent;
        return msg;
    }

    private void processEvent(final KeyEvent keyEvent) {
        mSensorManager.registerListener(new SensorEventListener() {

            @Override
            public void onSensorChanged(SensorEvent event) {
                if (!mEventHandler.hasMessages(GESTURE_REQUEST)) {
                    // The sensor took to long, ignoring.
                    return;
                }
                mEventHandler.removeMessages(GESTURE_REQUEST);
                if (event.values[0] == mProximitySensor.getMaximumRange()) {
                    Message msg = getMessageForKeyEvent(keyEvent);
                    mEventHandler.sendMessage(msg);
                }
                mSensorManager.unregisterListener(this);
            }

            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {}

        }, mProximitySensor, SensorManager.SENSOR_DELAY_FASTEST);
    }

}

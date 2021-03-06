package com.carnivalmobile.unity;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.support.v4.content.LocalBroadcastManager;

import com.carnival.sdk.AttributeMap;
import com.carnival.sdk.Carnival;
import com.carnival.sdk.CarnivalImpressionType;
import com.carnival.sdk.Message;
import com.carnival.sdk.MessageActivity;
import com.unity3d.player.UnityPlayer;

import org.json.JSONArray;
import org.json.JSONObject;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Date;

/**
 * Created by Affian on 10/06/15.
 *
 */
@SuppressWarnings("unused, unchecked")
public class CarnivalWrapper {

    private static final String CARNIVAL_UNITY = "Carnival";

    public static void startEngine(String projectNumber, String appKey) {
        Activity activity = UnityPlayer.currentActivity;

        String appPackage = activity.getApplicationContext().getPackageName();
        int resourceId = activity.getResources().getIdentifier("app_icon", "drawable", appPackage);
        if (resourceId != 0) {
            Carnival.setNotificationIcon(resourceId);
        }

        Carnival.startEngine(activity, appKey);

        LocalBroadcastManager broadcastManager = LocalBroadcastManager.getInstance(activity);
        broadcastManager.registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                int count = intent.getIntExtra(Carnival.EXTRA_UNREAD_MESSAGE_COUNT, 0);
                UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveUnreadCount", String.valueOf(count));
            }
        }, new IntentFilter(Carnival.ACTION_MESSAGE_COUNT_UPDATE));
        setWrapperInfo();
    }

    public static void updateLocation(double latitude, double longitude) {
        Location location = new Location("Unity");
        location.setLatitude(latitude);
        location.setLongitude(longitude);

        Carnival.updateLocation(location);
    }

    public static void deviceId() {
        Carnival.getDeviceId(new GenericErrorHandler() {
            @Override
            public void onSuccess(Object deviceId) {
                UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveDeviceID", String.valueOf(deviceId));
            }
        });
    }

    public static void logEvent(String value) {
        Carnival.logEvent(value);
    }

    public static void getMessages() {
        Carnival.getMessages(new GenericErrorHandler() {
            @Override
            public void onSuccess(ArrayList<Message> messages) {
                JSONArray messagesJson = new JSONArray();
                try {
                    Method toJsonMethod = Message.class.getDeclaredMethod("toJSON");
                    toJsonMethod.setAccessible(true);

                    for (Message message : messages) {
                        JSONObject messageJson = (JSONObject) toJsonMethod.invoke(message);
                        messagesJson.put(messageJson);
                    }
                } catch (Exception e) {
                    UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveError", e.getLocalizedMessage());
                }

                UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveMessagesJSONData", messagesJson.toString());
            }
        });
    }

    public static void setBooleanAttribute (String key, boolean value) {
        AttributeMap map = new AttributeMap();
        map.setMergeRules(AttributeMap.RULE_UPDATE);
        map.putBoolean(key, value);
        Carnival.setAttributes(map, new GenericErrorHandler());
    }

    public static void setIntegerAttribute (String key, int value) {
        AttributeMap map = new AttributeMap();
        map.setMergeRules(AttributeMap.RULE_UPDATE);
        map.putInt(key, value);
        Carnival.setAttributes(map, new GenericErrorHandler());
    }

    public static void setFloatAttribute (String key, float value) {
        AttributeMap map = new AttributeMap();
        map.setMergeRules(AttributeMap.RULE_UPDATE);
        map.putFloat(key, value);
        Carnival.setAttributes(map, new GenericErrorHandler());
    }

    public static void setStringAttribute (String key, String value) {
        AttributeMap map = new AttributeMap();
        map.setMergeRules(AttributeMap.RULE_UPDATE);
        map.putString(key, value);
        Carnival.setAttributes(map, new GenericErrorHandler());    }

    public static void setDateAttribute (String key, long value) {
        Date date = new Date(value);
        AttributeMap map = new AttributeMap();
        map.setMergeRules(AttributeMap.RULE_UPDATE);
        map.putDate(key, date);
        Carnival.setAttributes(map, new GenericErrorHandler());
    }

    public static void removeAttribute(String key) {
        Carnival.removeAttribute(key, new GenericErrorHandler());
    }


    public static void setUserId(String userId) {
        Carnival.setUserId(userId, new GenericErrorHandler());
    }

    public static void setUserEmail(String userEmail) {
        Carnival.setUserEmail(userEmail, new GenericErrorHandler());
    }

    private static void setWrapperInfo(){
        Method setWrapperMethod = null;
        try {
            Class[] cArg = new Class[2];
            cArg[0] = String.class;
            cArg[1] = String.class;

            setWrapperMethod = Carnival.class.getDeclaredMethod("setWrapper", cArg);
            setWrapperMethod.setAccessible(true);
            setWrapperMethod.invoke(null, "Unity", "1.0.0");
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            e.printStackTrace();
        }
    }

    public static void unreadCount() {
        Carnival.getUnreadMessageCount();
    }

    public static void removeMessage(String messageString) {
        Message message = getMessage(messageString);
        Carnival.deleteMessage(message, new GenericErrorHandler());
    }

    public static void registerMessageImpression(String messageString, int typeCode) {
        Message message = getMessage(messageString);
        CarnivalImpressionType type = null;

        if (typeCode == 0) type = CarnivalImpressionType.IMPRESSION_TYPE_IN_APP_VIEW;
        else if (typeCode == 1) type = CarnivalImpressionType.IMPRESSION_TYPE_STREAM_VIEW;
        else if (typeCode == 2) type = CarnivalImpressionType.IMPRESSION_TYPE_DETAIL_VIEW;

        if (type != null) {
            Carnival.registerMessageImpression(type, message);
        } else {
            UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveError", "Unable to determine Carnival Impression Type: " + typeCode);
        }

    }

    public static void markMessageAsRead(String messageString) {
        Message message = getMessage(messageString);
        Carnival.setMessageRead(message, new GenericErrorHandler());
    }

    private static Message getMessage(String messageString) {
        Message message = null;
        try {
            Constructor<Message> constructor;
            constructor = Message.class.getDeclaredConstructor(String.class);
            constructor.setAccessible(true);
            message = constructor.newInstance(messageString);
        } catch (Exception e) {
            UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveError", e.getLocalizedMessage());
        }
        return message;
    }

    public static void setInAppNotificationsEnabled(boolean enabled) {
        Carnival.setInAppNotificationsEnabled(enabled);
    }

    public static void showMessageDetail(String messageId) {
        Intent i = new Intent(UnityPlayer.currentActivity, MessageActivity.class);
        i.putExtra(Carnival.EXTRA_MESSAGE_ID, messageId);
        UnityPlayer.currentActivity.startActivity(i);
    }

    private static class GenericErrorHandler implements Carnival.AttributesHandler,
                                                        Carnival.MessagesHandler,
                                                        Carnival.MessageDeletedHandler,
                                                        Carnival.MessagesReadHandler,
                                                        Carnival.CarnivalHandler{
        @Override
        public void onSuccess() { }

        @Override
        public void onSuccess(ArrayList<Message> arrayList) { }


        public void onSuccess(Void aVoid) { }

        public void onSuccess(String string) { }

        @Override
        public void onSuccess(Object object) { }

        @Override
        public void onFailure(Error error) {
            UnityPlayer.UnitySendMessage(CARNIVAL_UNITY, "ReceiveError", error.getLocalizedMessage());
        }
    }
}
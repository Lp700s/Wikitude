package com.monkeybreadtech;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.support.annotation.Nullable;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.RelativeLayout;
import android.widget.Toast;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.wikitude.architect.ArchitectJavaScriptInterfaceListener;
import com.wikitude.architect.ArchitectStartupConfiguration;
import com.wikitude.architect.ArchitectView;
import com.wikitude.common.camera.CameraSettings;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import static android.content.ContentValues.TAG;
public class RNWikitudeManager extends SimpleViewManager<ViewGroup> implements LifecycleEventListener {
    public static final String REACT_CLASS = "RNWikitude";
    /**
     * holds the Wikitude SDK AR-View, this is where camera, markers, compass, 3D models etc. are rendered
     */
    private ArchitectView architectView;
    private RelativeLayout wrapperiView;
    private ThemedReactContext currentReactContext;
    private Activity currentActivity = null;
    private String architectWorldURL = null;
    private String licenseKey = null;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected ViewGroup createViewInstance(ThemedReactContext reactContext) {
        Log.e(this.getClass().getCanonicalName(), "createViewInstance() ?");
        currentReactContext = reactContext;
        currentActivity =  reactContext.getCurrentActivity();
        wrapperiView = new RelativeLayout(currentActivity);
        architectView =  new ArchitectView(currentActivity); //(ArchitectView)this.currentActivity.findViewById( R.id.architectView );//
        wrapperiView.addView(architectView);
        reactContext.addLifecycleEventListener(this);
        return wrapperiView;
    }

    @ReactProp(name = "licenseKey")
    public void setLicenseKey(RelativeLayout view, @Nullable String licenseKey) {
        this.licenseKey = licenseKey ;
    }

    @ReactProp(name = "architectWorldURL")
    public void setArchitectWorldURL(RelativeLayout view, @Nullable String architectWorldURL) {
        this.architectWorldURL = architectWorldURL ;
    }

    @ReactProp(name = "rendering")
    public void setRendering(RelativeLayout view, @Nullable String rendering) {
        if ("start".equals(rendering)) {
            // Start rendering
            if ( this.architectView != null ) {
                initView(this.architectView);
            }
        } else if ("stop".equals(rendering)) {
            // Stop rendering
            if ( this.architectView != null ) {
                this.architectView.onDestroy();
            }
        }
    }

    @ReactProp(name = "unload")
    public void setUnload(RelativeLayout view, @Nullable String unload) {
        if ("unload".equals(unload)) {
            // Unload!
            if ( this.architectView != null ) {
                this.architectView.onPause();
                this.architectView.onDestroy();
                this.architectView = null;
            }
        }
    }

    @Override
    public void onHostResume() {
        if ( this.architectView != null ) {
            // call mandatory live-cycle method of architectView
            this.architectView.onResume();
        }
    }
    @Override
    public void onHostPause() {
        if ( this.architectView != null ) {
            this.architectView.onPause();
        }
    }
    @Override
    public void onHostDestroy() {
        if ( this.architectView != null ) {
            this.architectView.onDestroy();
            this.architectView = null;
        }
    }
    private void initView(ArchitectView view){
        if (architectWorldURL == null || licenseKey == null){
            return;
        }
        final ArchitectStartupConfiguration config = new ArchitectStartupConfiguration();
        config.setLicenseKey(licenseKey);
        config.setFeatures(ArchitectView.getSupportedFeaturesForDevice(currentActivity));
        config.setCameraResolution(CameraSettings.CameraResolution.SD_640x480);
        try {
            /* first mandatory life-cycle notification */
            view.onCreate( config );
            view.onPostCreate();
        } catch (RuntimeException rex) {
            this.architectView = null;
            Toast.makeText(currentActivity, "can't create Architect View", Toast.LENGTH_SHORT).show();
            Log.e(this.getClass().getCanonicalName(), "Exception in ArchitectView.onCreate()", rex);
        }
        	/*
			 *	this enables remote debugging of a WebView on Android 4.4+ when debugging = true in AndroidManifest.xml
			 *	If you get a compile time error here, ensure to have SDK 19+ used in your ADT/Eclipse.
			 *	You may even delete this block in case you don't need remote debugging or don't have an Android 4.4+ device in place.
			 *	Details: https://developers.google.com/chrome-developer-tools/docs/remote-debugging
			 */
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            if ( 0 != ( currentActivity.getApplicationInfo().flags &= ApplicationInfo.FLAG_DEBUGGABLE ) ) {
                WebView.setWebContentsDebuggingEnabled(true);
            }
        }
        try {
            if (view == null)return;
            view.load(this.architectWorldURL);
        } catch (IOException e) {
            // unexpected, if error occurs here your path is invalid
            e.printStackTrace();
        }
        architectView.addArchitectJavaScriptInterfaceListener(getInterfaceListener());
    }

    private static WritableMap convertJsonToMap(JSONObject jsonObject) throws JSONException {
        WritableMap map = new WritableNativeMap();

        Iterator<String> iterator = jsonObject.keys();
        while (iterator.hasNext()) {
            String key = iterator.next();
            Object value = jsonObject.get(key);
            if (value instanceof JSONObject) {
                map.putMap(key, convertJsonToMap((JSONObject) value));
            } else if (value instanceof  JSONArray) {
                map.putArray(key, convertJsonToArray((JSONArray) value));
            } else if (value instanceof  Boolean) {
                map.putBoolean(key, (Boolean) value);
            } else if (value instanceof  Integer) {
                map.putInt(key, (Integer) value);
            } else if (value instanceof  Double) {
                map.putDouble(key, (Double) value);
            } else if (value instanceof String)  {
                map.putString(key, (String) value);
            } else {
                map.putString(key, value.toString());
            }
        }
        return map;
    }

    private static WritableArray convertJsonToArray(JSONArray jsonArray) throws JSONException {
        WritableArray array = new WritableNativeArray();

        for (int i = 0; i < jsonArray.length(); i++) {
            Object value = jsonArray.get(i);
            if (value instanceof JSONObject) {
                array.pushMap(convertJsonToMap((JSONObject) value));
            } else if (value instanceof  JSONArray) {
                array.pushArray(convertJsonToArray((JSONArray) value));
            } else if (value instanceof  Boolean) {
                array.pushBoolean((Boolean) value);
            } else if (value instanceof  Integer) {
                array.pushInt((Integer) value);
            } else if (value instanceof  Double) {
                array.pushDouble((Double) value);
            } else if (value instanceof String)  {
                array.pushString((String) value);
            } else {
                array.pushString(value.toString());
            }
        }
        return array;
    }

    private static JSONObject convertMapToJson(ReadableMap readableMap) throws JSONException {
        JSONObject object = new JSONObject();
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            switch (readableMap.getType(key)) {
                case Null:
                    object.put(key, JSONObject.NULL);
                    break;
                case Boolean:
                    object.put(key, readableMap.getBoolean(key));
                    break;
                case Number:
                    object.put(key, readableMap.getDouble(key));
                    break;
                case String:
                    object.put(key, readableMap.getString(key));
                    break;
                case Map:
                    object.put(key, convertMapToJson(readableMap.getMap(key)));
                    break;
                case Array:
                    object.put(key, convertArrayToJson(readableMap.getArray(key)));
                    break;
            }
        }
        return object;
    }

    private static JSONArray convertArrayToJson(ReadableArray readableArray) throws JSONException {
        JSONArray array = new JSONArray();
        for (int i = 0; i < readableArray.size(); i++) {
            switch (readableArray.getType(i)) {
                case Null:
                    break;
                case Boolean:
                    array.put(readableArray.getBoolean(i));
                    break;
                case Number:
                    array.put(readableArray.getDouble(i));
                    break;
                case String:
                    array.put(readableArray.getString(i));
                    break;
                case Map:
                    array.put(convertMapToJson(readableArray.getMap(i)));
                    break;
                case Array:
                    array.put(convertArrayToJson(readableArray.getArray(i)));
                    break;
            }
        }
        return array;
    }

    private void sendEvent(String eventName, @Nullable WritableMap params) {
        currentReactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);}
    public ArchitectJavaScriptInterfaceListener getInterfaceListener() {
        return new ArchitectJavaScriptInterfaceListener() {
            @Override
            public void onJSONObjectReceived(JSONObject jsonObject) {
                Log.v("onJSONObjectReceived",jsonObject.toString());
                try {
                    String type = jsonObject.getString("type");
                    if (type.equals("PROJECT_LOADED") || type.equals("TARGET_SCANNED") || type.equals("TARGET_LOST")) {
                        sendEvent("onWikitudeEvent", convertJsonToMap(jsonObject));
                    }
                } catch (JSONException e) {
                    Log.e(TAG, "onJSONObjectReceived: ", e);
                }
            }
        };
    }
}

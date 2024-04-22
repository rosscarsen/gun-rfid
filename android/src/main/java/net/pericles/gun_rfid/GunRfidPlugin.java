package net.pericles.gun_rfid;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;
import android.util.Log;
import android.view.KeyEvent;

import androidx.annotation.NonNull;

import com.handheld.uhfr.UHFRManager;
import com.uhf.api.cls.Reader;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import cn.pda.serialport.Tools;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * GunRfidPlugin
 */
public class GunRfidPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity

    private MethodChannel channel;
    private Context context;
    // 声明一个UHFRManager类型的变量
    private UHFRManager uhfRManager;


    // 声明一个boolean类型的变量，用于标识是否是阅读器
    private boolean isReader = false;

    String filter = "";

    private KeyReceiver keyReceiver;
    private boolean keyStatus = false;
    // 事件通道名称
    public static final String eventChannelName = "net.pericles.gun_rfid/eventChannel";
    // 事件通道
    private EventChannel.EventSink eventChannel;
    // 适配数据
    private final Map<Object, Object> resultMap = new HashMap<>();
    // 事件 Handler
    private Handler eventHandler;
    // 消息传递器
    private BinaryMessenger binaryMessenger;


    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "gun_rfid");
        channel.setMethodCallHandler(this);

        context = flutterPluginBinding.getApplicationContext();
        binaryMessenger = flutterPluginBinding.getBinaryMessenger();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + Build.VERSION.RELEASE);
                break;
            case "getConnectState":
                result.success(getConnectState());
                break;
            case "initRFID":
                result.success(initUHF());
                break;
            case "closeRFID":
                result.success(closeModule());
                break;
            case "startInventory":
                resultMap.clear();
                new EventChannel(binaryMessenger, eventChannelName).setStreamHandler(
                        new EventChannel.StreamHandler() {
                            @Override
                            public void onListen(Object args, final EventChannel.EventSink events) {
                                eventChannel = events;
                                resultMap.clear();
                                eventHandler = new Handler();
                                isReader = true;
                                runnable.run();

                            }

                            @Override
                            public void onCancel(Object args) {
                                if (uhfRManager != null) {
                                    uhfRManager.asyncStopReading();
                                }
                                eventHandler.removeCallbacks(runnable);
                                eventHandler = null;
                                resultMap.clear();
                                eventChannel = null;
                                isReader = false;
                            }
                        });
                result.success(true);
                break;
            case "registerKey":
                // 注册按键
                registerKeyCodeReceiver();
                result.success(keyStatus);
                break;
            case "unregisterKey":
                // 注销按键
                unRegisterKey();
                result.success(keyStatus);
                break;
            case "isReader":
                result.success(isReader);
                break;
            case "checkKeyStatus":
                result.success(keyStatus);
                break;
            case "setFilter":
                filter = call.argument("filter");
                result.success(true);
                break;
            case "setPower":
                int power = call.argument("power");
                result.success(setPower(power));
                break;
            case "editEPC":
                String oldEPC = call.argument("oldEPC");
                String newEPC = call.argument("newEPC");
                result.success(editEPC(oldEPC, newEPC));
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        if (context != null && keyReceiver != null) {
            context.unregisterReceiver(keyReceiver);
            keyReceiver = null;
        }
        if (eventHandler != null) {
            eventChannel.endOfStream();
            eventHandler.removeCallbacks(runnable);
            eventHandler = null;
            eventChannel = null;
        }
        isReader = false;
    }

    /* 注册按键 */
    private void registerKeyCodeReceiver() {
        keyReceiver = new KeyReceiver();
        IntentFilter filter = new IntentFilter();
        filter.addAction("android.rfid.FUN_KEY");
        filter.addAction("android.intent.action.FUN_KEY");
        context.registerReceiver(keyReceiver, filter);
        keyStatus = true;
    }

    //获取连接状态
    private boolean getConnectState() {
        return uhfRManager != null;
    }

    // 注销按键
    public void unRegisterKey() {
        if (keyReceiver != null) {
            context.unregisterReceiver(keyReceiver);
            keyReceiver = null;
        }
        keyStatus = false;
    }

    /**
     * 初始化UHF模块
     */

    private boolean initUHF() {
        boolean isConnectUHF;
        uhfRManager = UHFRManager.getInstance();
        if (uhfRManager != null) {
            Reader.READER_ERR reader_err = uhfRManager.setPower(33, 33);
            if (reader_err == Reader.READER_ERR.MT_OK_ERR) {
                isConnectUHF = true;
                uhfRManager.setRegion(Reader.Region_Conf.valueOf(1));
                setParam();
            } else {
                Reader.READER_ERR err1 = uhfRManager.setPower(30, 30);
                if (err1 == Reader.READER_ERR.MT_OK_ERR) {
                    isConnectUHF = true;
                    uhfRManager.setRegion(Reader.Region_Conf.valueOf(1));
                    setParam();
                } else {
                    isConnectUHF = false;
                }
            }
        } else {
            isConnectUHF = false;
        }
        return isConnectUHF;
    }

    /**
     * 设置参数
     */
    private void setParam() {
        // session
        uhfRManager.setGen2session(0);
        // target
        uhfRManager.setTarget(0);
        // q value
        uhfRManager.setQvaule(0);
        // FastId
        uhfRManager.setFastID(false);
    }

    /**
     * 关闭模块
     */
    private boolean closeModule() {
        if (uhfRManager != null) {// close uhf module
            uhfRManager.close();
            uhfRManager = null;
        }
        return true;
    }

    // 盘存线程
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {
            if (uhfRManager == null) {
                eventChannel.success(resultMap);
            }
            if (isReader) {
                List<Reader.TAGINFO> listTag;
                listTag = uhfRManager.tagEpcTidInventoryByTimer((short) 50);
                Log.d("run", "run: "+listTag);
                Log.d("run", "run: "+uhfRManager);
                if (listTag == null) {
                    uhfRManager.asyncStopReading();
                    uhfRManager.asyncStartReading();
                }
                Log.d("run", "run: "+(listTag != null)+"//"+!listTag.isEmpty());
                if (listTag != null && !listTag.isEmpty()) {
                    for (Reader.TAGINFO tagInfo : listTag) {
                        if (tagInfo.EmbededData != null) {
                            String epcAndTid = Tools.Bytes2HexString(tagInfo.EmbededData, tagInfo.EmbededData.length);
                            String epc = Tools.Bytes2HexString(tagInfo.EpcId, tagInfo.EpcId.length);
                            //Log.d("resultMap", "resultMap: " + epcAndTid+"//////"+epc);
                            String lastThreeChars = epc.substring(epc.length() - 4, epc.length() - 1);
                            if (epcAndTid != null && !epcAndTid.equals("")) {
                                if (filter == null || filter.equals("") || lastThreeChars.equals(filter)) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        resultMap.putIfAbsent(epcAndTid, epc);
                                    }
                                }
                            }
                        }
                    }

                    if (eventChannel != null) {
                        eventChannel.success(resultMap);
                    }
                }
                eventHandler.postDelayed(this, 100);
            } else {
                eventChannel.error("error", "Failed to start reading", null);
                if (context != null && keyReceiver != null) {
                    context.unregisterReceiver(keyReceiver);
                    keyReceiver = null;
                }
                if (eventHandler != null) {
                    eventChannel.endOfStream();
                    eventHandler.removeCallbacks(runnable);
                    eventHandler = null;
                    eventChannel = null;
                }
            }
        }
    };

    private class KeyReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            try {
                int keyCode = intent.getIntExtra("keyCode", 0);
                if (keyCode == 0) {
                    keyCode = intent.getIntExtra("keycode", 0);
                }
                boolean keyDown = intent.getBooleanExtra("keydown", false);
                if (keyDown) {
                    /// Toast.makeText(MainActivity.this, "KeyReceiver:keyCode = down" + keyCode,
                    /// Toast.LENGTH_SHORT).show();
                } else {
                    /// Toast.makeText(MainActivity.this, "KeyReceiver:keyCode = up" + keyCode,
                    /// Toast.LENGTH_SHORT).show();
                    switch (keyCode) {
                        case KeyEvent.KEYCODE_F1:
                        case KeyEvent.KEYCODE_F2:
                        case KeyEvent.KEYCODE_F3:
                            break;
                        case KeyEvent.KEYCODE_F5:
                        case KeyEvent.KEYCODE_F4:// 6100
                        case KeyEvent.KEYCODE_F7:// H3100
                            Log.i("onReceive", "onReceive: 按键按下");

                            MethodChannel flutterChannel = new MethodChannel(binaryMessenger, "net.pericles.gun_rfid/keyMethodChannel");
                            Log.d("isReader", "isReader: "+isReader);
                            //如果当前是盘点状态,停止盘点
                            if (isReader) {
                                flutterChannel.invokeMethod("stopInventoryFromKeyEvent", null);
                            } else {
                                flutterChannel.invokeMethod("startInventoryFromKeyEvent", null);
                            }
                            break;
                    }
                }
            } catch (Exception e) {
                Log.e("KeyReceiver", "Error in onReceive", e);
            }
        }
    }

    /**
     * 设置功率
     */
    private boolean setPower(int power) {
        if (uhfRManager == null) {
            return false;
        }
        Reader.READER_ERR err = uhfRManager.setPower(power, power);
        if (err == Reader.READER_ERR.MT_OK_ERR) {
            return true;
        } else {
            return false;
        }
    }

    //修改EPC
    private boolean editEPC(String oldEpc, String newEpc) {
        String accessStr = "00000000";
        if (accessStr == null || accessStr.length() == 0) {
            return false;
        }
        if (!matchHex(accessStr) || accessStr.length() != 8) {
            return false;
        }
        if (!matchHex(newEpc) || newEpc.length() % 4 != 0) {
            return false;
        }
        //访问密码
        byte[] accessPassword = Tools.HexString2Bytes(accessStr);
        //新EPC值
        byte[] writeDataBytes = Tools.HexString2Bytes(newEpc);
        //旧的epc
        byte[] epc = Tools.HexString2Bytes(oldEpc);
        Reader.READER_ERR er;
        er = uhfRManager.writeTagEPCByFilter(writeDataBytes, accessPassword, (short) 1000, epc, 1, 2, true);
        if (er == Reader.READER_ERR.MT_OK_ERR) {
            return true;
        } else {
            return false;
        }
    }

    private boolean matchHex(String data) {
        boolean flag = false;
        String regEx = "-?[0-9a-fA-F]+";
        Pattern pattern = Pattern.compile(regEx);
        Matcher matcher = pattern.matcher(data);
        flag = matcher.matches();
        return flag;
    }
}

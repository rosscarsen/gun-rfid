import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gun_rfid/gun_rfid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _gunRfidPlugin = GunRfid();
  bool _isConnect = false;
  bool _isReader = false;
  Map<String, String>? rfidRet;
  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _epcController = TextEditingController();
  List<int> powerList = [5, 10, 15, 20, 25, 30, 33];

  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    initRFID();
    getKeyData();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> getKeyData() async {
    _gunRfidPlugin.keyStartInventory((value) {
      setState(() {
        rfidRet = value
            .map((key, value) => MapEntry(key.toString(), value.toString()));
      });
    });
  }

  @override
  void dispose() {
    closeRFID();
    WidgetsBinding.instance.removeObserver(this);
    _gunRfidPlugin.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 应用程序进入前台
        await _gunRfidPlugin.initRFID();
        break;
      case AppLifecycleState.inactive:
        // 应用程序变为非活动状态
        //print('App Inactive');
        break;
      case AppLifecycleState.paused:
        // 应用程序进入后台
        await _gunRfidPlugin.closeRFID();
        break;
      case AppLifecycleState.detached:
        // 应用程序被挂起
        // print('App Detached');
        break;
      case AppLifecycleState.hidden:
    }
  }

  //初始化RFID设备
  Future<void> initRFID() async {
    bool isConnect = await _gunRfidPlugin.initRFID();
    setState(() {
      _isConnect = isConnect;
    });
  }

  //关闭RFID设备
  Future<void> closeRFID() async {
    bool isConnect = await _gunRfidPlugin.closeRFID();
    setState(() {
      _isConnect = isConnect;
    });
  }
  //监听前台与后台切换

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Builder(builder: (context) {
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('连接状态: $_isConnect\n'),
                Text('读取模式: $_isReader\n'),
                Wrap(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          _gunRfidPlugin.getConnectState().then(
                                (value) => setState(() {
                                  _isConnect = value;
                                }),
                              );
                        },
                        child: const Text('获取连接状态')),
                    ElevatedButton(
                        onPressed: () {
                          _gunRfidPlugin.getReadState().then(
                            (value) {
                              setState(() {
                                _isReader = value;
                              });
                            },
                          );
                        },
                        child: const Text('获取读取模式')),
                    ElevatedButton(
                        child: const Text('注册按键'),
                        onPressed: () async {
                          await _gunRfidPlugin.registerKey();
                        }),
                    ElevatedButton(
                      child: const Text('注销按键'),
                      onPressed: () async {
                        await _gunRfidPlugin.unregisterKey();
                      },
                    ),
                    ElevatedButton(
                      child: const Text('开始盤點'),
                      onPressed: () {
                        _gunRfidPlugin.startInventory((value) {
                          debugPrint("$value");
                          setState(() {
                            rfidRet = value.map((key, value) =>
                                MapEntry(key.toString(), value.toString()));
                          });
                        });
                      },
                    ),
                    ElevatedButton(
                      child: const Text('停止盘点'),
                      onPressed: () {
                        _gunRfidPlugin.stopInventory(); //停止盘点
                      },
                    ),
                    ElevatedButton(
                      child: const Text('清空数据'),
                      onPressed: () {
                        setState(() {
                          rfidRet = {};
                        });
                      },
                    ),
                    ElevatedButton(
                      child: const Text('重启模块'),
                      onPressed: () async {
                        bool ret = await _gunRfidPlugin.restartRFID();
                        if (ret) {
                          _epcController.text = "";
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("重启模块成功")),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("重启模块失败")),
                            );
                          }
                        }
                      },
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _filterController,
                        decoration: InputDecoration(
                          hintText: "设置过滤",
                          suffixIcon: TextButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                var ret = await _gunRfidPlugin
                                    .setFilter(_filterController.text);
                                if (ret) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("设置过滤成功")),
                                    );
                                  }
                                }
                              },
                              child: const Text("设置")),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text("设置功率"),
                      DropdownButtonFormField(
                          items: powerList.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                          value: 25,
                          onChanged: (value) async {
                            bool ret = await _gunRfidPlugin.setPower(value!);
                            if (ret) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("设置功率成功")),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("设置功率失败")),
                                );
                              }
                            }
                          }),
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                        controller: _epcController,
                        decoration: InputDecoration(
                          hintText: "点击选中已经读取到的标签,再修改EPC",
                          suffixIcon: TextButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                ClipboardData? clipboardData =
                                    await Clipboard.getData(
                                        Clipboard.kTextPlain);
                                if (clipboardData != null) {
                                  String? oldEPC = clipboardData.text;
                                  var ret = await _gunRfidPlugin.editEPC(
                                      oldEPC!, _epcController.text);
                                  if (ret) {
                                    _epcController.text = "";
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("修改EPC成功")),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text("修改EPC失败")),
                                      );
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("末有选中的EPC")),
                                    );
                                  }
                                }
                              },
                              child: const Text("修改EPC")),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: rfidRet?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        subtitle: Text(rfidRet!.values.toList()[index]),
                        title: Text(rfidRet!.keys.toList()[index]),
                        tileColor:
                            selectedIndex == index ? Colors.blue : Colors.white,
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                          Clipboard.setData(ClipboardData(
                              text: rfidRet!.values.toList()[index]));
                        });
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:get/get.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:usb_serial/usb_serial.dart';
// ignore: depend_on_referenced_packages
//import 'package:flutter_libserialport/flutter_libserialport.dart';
// ignore: depend_on_referenced_packages
import 'package:usbmag_common/usbmag_common.dart';

void main() {
  runApp(const MyApp());
}

class CGetX extends GetxController with CUsbMagHelper {
  @override
  void onInit() {
    init();

    openDevice();

    super.onInit();
  }

  // void openDevice() async {
  //   mDebugText.value = "debug";
  //   var port_name = "";
  //   var ps = SerialPort.availablePorts;
  //   mDebugText.value = "debug2";
  //   if (ps.isNotEmpty) {
  //     port_name = ps.first;
  //     var dt = "port:";
  //     for (var d in ps) {
  //       dt += d;
  //       dt += "---";
  //     }
  //     mDebugText.value = dt;
  //   } else {
  //     mDebugText.value = "no port";
  //   }
  //   if (port_name == "") return;

  //   mPort = SerialPort(port_name);
  //   bool? openResult = mPort?.openReadWrite();
  //   if (!openResult!) {
  //     Get.snackbar("Failed", "Failed to open device:${"test"}",
  //         snackPosition: SnackPosition.BOTTOM);
  //     return;
  //   } else {
  //     Get.snackbar("Success", "success to open device:${"test"}",
  //         snackPosition: SnackPosition.BOTTOM);
  //   }

  //   mOpen.value = true;

  //   //await mPort!.setDTR(true);
  //   //await mPort!.setRTS(true);

  //   SerialPortConfig config = mPort!.config;
  //   config.baudRate = 115200;
  //   config.bits = 8;
  //   config.stopBits = 1;
  //   config.parity = 0;
  //   mPort!.config = config;

  //   final reader = SerialPortReader(mPort!);
  //   reader.stream.listen((Uint8List dataevent) {
  //     String data = String.fromCharCodes(dataevent);

  //     if (mSingleOrThree.value == -1) {
  //       mSingleOrThreeFirstData += data;
  //       checkSingle();
  //       return;
  //     }

  //     if (mCurIndex.value == 0) {
  //       handleRcData(data);
  //     }

  //     if (mCurIndex.value == 1) {
  //       handleVcData(data);
  //     }

  //     if (mCurIndex.value == 2) {
  //       handleCmdData(data);
  //     }
  //   });
  // }
  void openDevice() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();

    if (devices.isEmpty) {
      return;
    }

    mPort = await devices[0].create();
    if (mPort == null) return;

    bool openResult = await mPort!.open();
    if (!openResult) {
      Get.snackbar("Failed", "Failed to open device",
          snackPosition: SnackPosition.BOTTOM);
      return;
    } else {
      Get.snackbar("Success", "success to open device",
          snackPosition: SnackPosition.BOTTOM);
    }

    mOpen.value = true;

    await mPort!.setDTR(true);
    await mPort!.setRTS(true);

    mPort!.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    mPort!.inputStream!.listen((Uint8List dataevent) {
      String data = String.fromCharCodes(dataevent);

      if (mSingleOrThree.value == -1) {
        mSingleOrThreeFirstData += data;
        checkSingle();
        return;
      }

      if (mCurIndex.value == 0) {
        handleRcData(data);
      }

      if (mCurIndex.value == 1) {
        handleVcData(data);
      }

      if (mCurIndex.value == 2) {
        handleCmdData(data);
      }
    });
  }

  void closeDevice() {
    mPort?.close();
    mOpen.value = false;
    mSingleOrThreeFirstData = "";
    mSingleOrThree.value = -1;
  }

  @override
  void sendMsg(String msg, {bool setCur = false}) {
    if (mOpen.value) {
      mPort?.write(Uint8List.fromList(msg.codeUnits));
      if (setCur) {
        mCurCmd = msg;
      }
    }
  }

  UsbPort? mPort;

  var mCurIndex = 0.obs;
}

class CMainPanel extends StatelessWidget {
  const CMainPanel({super.key});

  @override
  Widget build(BuildContext context) {
    CGetX gx = Get.find();
    return gx.getMainPanel();
  }
}

class CCalibrate extends StatelessWidget {
  const CCalibrate({super.key});

  @override
  Widget build(BuildContext context) {
    CGetX gx = Get.find();
    return gx.getCalibratePanel();
  }
}

class CCmd extends StatelessWidget {
  const CCmd({super.key});

  @override
  Widget build(BuildContext context) {
    CGetX gx = Get.find();
    return gx.getCmdPanel();
  }
}

class CConfig extends StatelessWidget {
  const CConfig({super.key});

  @override
  Widget build(BuildContext context) {
    CGetX gx = Get.find();
    return gx.getConfigPanel();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Get.put(CGetX());
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'NotoSansSC'),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  Widget? getCurPage(int curIndex) {
    if (curIndex == 0) {
      return const CMainPanel();
    }
    if (curIndex == 1) {
      return const CCalibrate();
    }
    if (curIndex == 2) {
      return const CCmd();
    }
    if (curIndex == 3) {
      return const CConfig();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    CGetX gx = Get.find();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 72, 96, 107),
          title: Obx(() => gx.mDebug.value
              ? Text(gx.mDebugText.value)
              : Text(gx.getLan() == 1 ? "MultiDimension USBMAG" : "多维科技 磁力计")),
          actions: [
            Obx(() => gx.mOpen.value
                ? Center(
                    child: Text(
                    gx.getLan() == 1 ? "Connected" : "磁力计已连接",
                    textScaler: const TextScaler.linear(1.3),
                  ))
                : Center(
                    child: Text(
                    gx.getLan() == 1 ? "Disconnect" : "磁力计断开",
                    textScaler: const TextScaler.linear(1.3),
                    style: const TextStyle(color: Colors.red),
                  )))
          ],
        ),
        body: Center(
          child: Obx(() => getCurPage(gx.mCurIndex.value)!),
        ),
        bottomNavigationBar: Obx(() => BottomNavigationBar(
              fixedColor: Colors.black,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                    label: gx.getLan() == 1 ? "Main Panel" : "主面板",
                    icon: const Icon(Icons.home)),
                BottomNavigationBarItem(
                    label: gx.getLan() == 1 ? "Calibrate" : "校准",
                    icon: const Icon(Icons.compass_calibration)),
                BottomNavigationBarItem(
                    label: gx.getLan() == 1 ? "Cmd" : "命令",
                    icon: const Icon(Icons.keyboard_command_key)),
                BottomNavigationBarItem(
                    label: gx.getLan() == 1 ? "Config" : "配置",
                    icon: const Icon(Icons.settings)),
              ],
              currentIndex: gx.mCurIndex.value,
              onTap: (int i) {
                if (gx.mOpen.value) {
                  gx.sendMsg("PE", setCur: true);
                }
                gx.mCurIndex.value = i;
              },
            )));
  }
}

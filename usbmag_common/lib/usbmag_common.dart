// ignore_for_file: prefer_const_constructors

library flutter_application_usbmag_common;

// ignore: depend_on_referenced_packages
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:get/get.dart';
// ignore: depend_on_referenced_packages
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:getwidget/getwidget.dart';
// ignore: depend_on_referenced_packages
import 'package:file_picker/file_picker.dart';

class CMagData {
  double mTime = 0;
  double mX = 0;
  double mY = 0;
  double mZ = 0;
  CMagData(this.mTime, this.mX, this.mY, this.mZ);
}

class CMagRvData {
  double mTime = 0;
  double mV = 0;
  CMagRvData(this.mTime, this.mV);
}

mixin CUsbMagHelper {
  void init() {
    mCmdCtl.addListener(() {
      if (mCmdCtl.text.isNotEmpty) {
        mCmdCmd = mCmdCtl.text;
      }
    });

    mParamCtl.text = mParam.toString();
    mParamCtl.addListener(() {
      if (mParamCtl.text.isNotEmpty) {
        double? pc = double.tryParse(mParamCtl.text);
        if (pc != null) {
          mParam = pc;
        }
      }
    });

    getStoreLan();
  }

  var mCalibrateDir = "X".obs;
  var mPosVol = 0.0.obs;
  var mNegVol = 0.0.obs;
  var mSensitive = 0.0.obs;
  var mOffsetVol = 0.0.obs;
  var mMagRvChartData = <CMagRvData>[];
  int mMaxCount = 500;
  var mStopEnable = true.obs;
  var mSetTemp = false.obs;
  var mSetEprom = false.obs;
  TextEditingController mParamCtl = TextEditingController(text: "0.485");
  double mParam = 0.485;
  var mCalMsg = "";
  ChartSeriesController? mChartSeriesControllerRV;

  var mSingleOrThree = (-1).obs;
  String mSingleOrThreeFirstData = "";

  var mMainMsg = "";
  ChartSeriesController? mChartSeriesControllerX;
  ChartSeriesController? mChartSeriesControllerY;
  ChartSeriesController? mChartSeriesControllerZ;

  var mMagChartData = <CMagData>[];
  var mValX = "".obs;
  var mValY = "".obs;
  var mValZ = "".obs;

  var mOpen = false.obs;

  var mExportCount = 100.0.obs;
  var mExportPath = "".obs;

  var mLan = "English".obs;
  int getLan() {
    return mLan.value == "English" ? 1 : 2;
  }

  var mCurCmd = "";

  TextEditingController mCmdCtl = TextEditingController();
  final ScrollController mScrollController = ScrollController();

  var mCmdRevText = "".obs;
  var mCmdCmd = "";

  var mEsp32IP = "IP".obs;

  var mDebugText = "".obs;
  var mDebug = false.obs;

  void sendMsg(String msg, {bool setCur = false});

  Widget getMainPanel() {
    return Column(
      children: [
        //chart here
        Expanded(
            flex: 8,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(() => Column(
                      children: mSingleOrThree.value == -1
                          ? []
                          : mSingleOrThree.value == 1
                              ? [
                                  const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Text("X",
                                          textScaler: TextScaler.linear(1.3),
                                          style: TextStyle(color: Colors.blue)),
                                      Text("Y",
                                          textScaler: TextScaler.linear(1.3),
                                          style:
                                              TextStyle(color: Colors.green)),
                                      Text("Z",
                                          textScaler: TextScaler.linear(1.3),
                                          style:
                                              TextStyle(color: Colors.orange))
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Obx(() => Text(mValX.value,
                                          textScaler:
                                              const TextScaler.linear(1.3))),
                                      Obx(() => Text(mValY.value,
                                          textScaler:
                                              const TextScaler.linear(1.3))),
                                      Obx(() => Text(mValZ.value,
                                          textScaler:
                                              const TextScaler.linear(1.3)))
                                    ],
                                  ),
                                ]
                              : [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Obx(() => Text(mValX.value,
                                          textScaler:
                                              const TextScaler.linear(1.3))),
                                    ],
                                  ),
                                ])),
                ),
                Expanded(
                  child: Obx(() => SfCartesianChart(
                      title: ChartTitle(
                          text: "Oe", alignment: ChartAlignment.near),
                      legend: Legend(
                          isVisible: true, position: LegendPosition.bottom),
                      primaryXAxis: NumericAxis(
                          title: AxisTitle(text: "Time(S)"), isVisible: true),
                      series: mSingleOrThree.value == -1
                          ? <SplineSeries>[]
                          : (mSingleOrThree.value == 1
                              ? <SplineSeries>[
                                  SplineSeries<CMagData, double>(
                                      onRendererCreated:
                                          (ChartSeriesController controller) {
                                        mChartSeriesControllerX = controller;
                                      },
                                      name: "X",
                                      color: Colors.blue,
                                      dataSource: mMagChartData,
                                      xValueMapper: (CMagData md, _) =>
                                          md.mTime,
                                      yValueMapper: (CMagData md, _) => md.mX),
                                  SplineSeries<CMagData, double>(
                                      onRendererCreated:
                                          (ChartSeriesController controller) {
                                        mChartSeriesControllerY = controller;
                                      },
                                      name: "Y",
                                      color: Colors.green,
                                      dataSource: mMagChartData,
                                      xValueMapper: (CMagData md, _) =>
                                          md.mTime,
                                      yValueMapper: (CMagData md, _) => md.mY),
                                  SplineSeries<CMagData, double>(
                                      onRendererCreated:
                                          (ChartSeriesController controller) {
                                        mChartSeriesControllerZ = controller;
                                      },
                                      name: "Z",
                                      color: Colors.orange,
                                      dataSource: mMagChartData,
                                      xValueMapper: (CMagData md, _) =>
                                          md.mTime,
                                      yValueMapper: (CMagData md, _) => md.mZ),
                                ]
                              : <SplineSeries>[
                                  SplineSeries<CMagData, double>(
                                      onRendererCreated:
                                          (ChartSeriesController controller) {
                                        mChartSeriesControllerX = controller;
                                      },
                                      name: "",
                                      color: Colors.blue,
                                      dataSource: mMagChartData,
                                      xValueMapper: (CMagData md, _) =>
                                          md.mTime,
                                      yValueMapper: (CMagData md, _) => md.mX),
                                ]))),
                ),
              ],
            )),
        //button
        Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              textStyle: TextStyle(fontFamily: 'NotoSansSC'),
                              onPressed: mSingleOrThree.value == -1
                                  ? null
                                  : () {
                                      sendMsg("PE");
                                      Future.delayed(
                                          const Duration(milliseconds: 500),
                                          () {
                                        mMainMsg = "";
                                        clearChartDataRC();
                                        sendMsg("RC", setCur: true);
                                      });
                                    },
                              text: getLan() == 1 ? "Start" : "开始"))),
                      const Spacer(flex: 3),
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('PE');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Stop" : "暂停"))))
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('RE');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Resume" : "恢复")))),
                      const Spacer(flex: 3),
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                clearChartDataRC();
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Reset Chart" : "重设图表"))))
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('RS');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Open Offset" : "开失调磁场")))),
                      const Spacer(flex: 3),
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('RO');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Close Offset" : "关失调磁场"))))
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('PG 1');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Dynamic Range" : "动态范围")))),
                      const Spacer(flex: 3),
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('PG 8');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "Low Noise" : "低噪声"))))
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg("DB 13");
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "ADC Fast" : "快速模数转换")))),
                      const Spacer(flex: 3),
                      Expanded(
                          flex: 3,
                          child: Obx(() => GFButton(
                              onPressed: () {
                                sendMsg('DB 16');
                              },
                              child: Text(
                                  style: TextStyle(fontFamily: 'NotoSansSC'),
                                  getLan() == 1 ? "ADC Normal" : "正常模数转换"))))
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget getCalibratePanel() {
    return Column(
      children: [
        Expanded(
            flex: 4,
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Obx(() => DropdownButton(
                        value: mCalibrateDir.value,
                        items: (mSingleOrThree.value == 1
                                ? ["X", "Y", "Z"]
                                : ["X"])
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          mCalibrateDir.value = newValue!;
                        })),
                    Obx(() => ElevatedButton(
                        onPressed: mSingleOrThree.value != -1
                            ? () {
                                sendMsg("PE");

                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  mPosVol.value = -999999.9;
                                  mNegVol.value = 999999.9;
                                  mStopEnable.value = true;
                                  mSetTemp.value = false;
                                  mSetEprom.value = false;
                                  mCalMsg = "";
                                  clearChartDataVC();
                                  sendMsg("VC", setCur: true);
                                });
                              }
                            : null,
                        child:
                            Text(getLan() == 1 ? "Start Calibrate" : "开始校准"))),
                    Obx(() => ElevatedButton(
                        onPressed: mStopEnable.value
                            ? () {
                                sendMsg("PE");
                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  mSetTemp.value = true;
                                  mSetEprom.value = true;
                                });
                              }
                            : null,
                        child: Text(getLan() == 1 ? "Stop" : "停止"))),
                    Obx(() => ElevatedButton(
                        onPressed: () {
                          clearChartDataVC();
                        },
                        child: Text(getLan() == 1 ? "Reset Chart" : "重设图表"))),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  child: TextField(
                    controller: mParamCtl,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.bottom,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Text(
                              getLan() == 1 ? "Max Negv" : "最大负电压",
                              textScaler: const TextScaler.linear(1.1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                            child: Obx(() => Text(
                                  mNegVol.toStringAsFixed(6),
                                  textScaler: const TextScaler.linear(1.1),
                                )),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                            child: Obx(() => Text(
                                  mSensitive.toStringAsFixed(6),
                                  textScaler: const TextScaler.linear(1.1),
                                )),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Text(
                              getLan() == 1 ? "mV/V/Oe" : "灵  敏  度",
                              textScaler: const TextScaler.linear(1.1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Text(
                              getLan() == 1 ? "Max Pos" : "最大正电压",
                              textScaler: const TextScaler.linear(1.1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                            child: Obx(() => Text(
                                  mPosVol.toStringAsFixed(6),
                                  textScaler: const TextScaler.linear(1.1),
                                )),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                            child: Obx(() => Text(
                                  mOffsetVol.toStringAsFixed(6),
                                  textScaler: const TextScaler.linear(1.1),
                                )),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: const BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20))),
                            child: Text(
                              getLan() == 1 ? "Offset" : "失调电压",
                              textScaler: const TextScaler.linear(1.1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => ElevatedButton(
                          onPressed: mSetTemp.value
                              ? () {
                                  if (mSingleOrThree.value == 0) {
                                    sendMsg(
                                        'SM ${mSensitive.toStringAsFixed(6)}');
                                  }
                                  if (mSingleOrThree.value == 1) {
                                    sendMsg(
                                        'SM $mCalibrateDir ${mSensitive.toStringAsFixed(6)}');
                                  }
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    if (mSingleOrThree.value == 0) {
                                      sendMsg(
                                          'OM ${mOffsetVol.toStringAsFixed(6)}');
                                    }
                                    if (mSingleOrThree.value == 1) {
                                      sendMsg(
                                          'OM $mCalibrateDir ${mOffsetVol.toStringAsFixed(6)}');
                                    }
                                    Get.snackbar(
                                        getLan() == 1 ? "Notify" : "通知",
                                        getLan() == 1 ? "Success" : "设置成功",
                                        snackPosition: SnackPosition.BOTTOM);
                                  });
                                }
                              : null,
                          child: Text(
                              getLan() == 1 ? "Set Sensor Only" : "仅传感器设置"))),
                      Obx(() => ElevatedButton(
                          onPressed: mSetEprom.value
                              ? () {
                                  if (mSingleOrThree.value == 0) {
                                    sendMsg(
                                        'SW ${mSensitive.toStringAsFixed(6)}');
                                  }
                                  if (mSingleOrThree.value == 1) {
                                    sendMsg(
                                        'SW $mCalibrateDir ${mSensitive.toStringAsFixed(6)}');
                                  }
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    if (mSingleOrThree.value == 0) {
                                      sendMsg(
                                          'OW ${mOffsetVol.toStringAsFixed(6)}');
                                    }
                                    if (mSingleOrThree.value == 1) {
                                      sendMsg(
                                          'OW $mCalibrateDir ${mOffsetVol.toStringAsFixed(6)}');
                                    }
                                    Get.snackbar(
                                        getLan() == 1 ? "Notify" : "通知",
                                        getLan() == 1 ? "Success" : "设置成功",
                                        snackPosition: SnackPosition.BOTTOM);
                                  });
                                }
                              : null,
                          child: Text(
                              getLan() == 1 ? "Save in EEPROM" : "存储在EEPROM"))),
                    ],
                  ),
                )
              ],
            )),
        Expanded(
            flex: 6,
            child: Obx(() => SfCartesianChart(
                title:
                    ChartTitle(text: "Voltage", alignment: ChartAlignment.near),
                primaryXAxis: NumericAxis(
                    title: AxisTitle(text: "Data Point"), isVisible: true),
                series: mSingleOrThree.value == -1
                    ? <SplineSeries>[]
                    : <SplineSeries>[
                        SplineSeries<CMagRvData, double>(
                            onRendererCreated:
                                (ChartSeriesController controller) {
                              mChartSeriesControllerRV = controller;
                            },
                            name: "",
                            color: Colors.orange,
                            dataSource: mMagRvChartData,
                            xValueMapper: (CMagRvData md, _) => md.mTime,
                            yValueMapper: (CMagRvData md, _) => md.mV),
                      ])))
      ],
    );
  }

  Widget getCmdPanel() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 0, 0, 0),
                child: TextField(
                  controller: mCmdCtl,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.bottom,
                  decoration: const InputDecoration(hintText: "Input Command"),
                ),
              ),
            ),
            Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 5, 0),
                  child: GFButton(
                      onPressed: () {
                        sendMsg(mCmdCmd);
                      },
                      child: Text(
                          style: TextStyle(fontFamily: 'NotoSansSC'),
                          getLan() == 1 ? "Send" : "发送")),
                )),
          ],
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Scrollbar(
            controller: mScrollController,
            child: ListView(
              controller: mScrollController,
              children: [
                Obx(() => Text(
                      mCmdRevText.value,
                      textScaler: const TextScaler.linear(1.3),
                      textAlign: TextAlign.center,
                    ))
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget getConfigPanel() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(getLan() == 1 ? "Language:" : "语言："),
            Row(
              children: [
                Obx(() => Radio(
                    value: "中文",
                    groupValue: mLan.value,
                    onChanged: (lan) async {
                      mLan.value = lan.toString();
                      saveStoreLan(lan.toString());
                    })),
                const Text("中文"),
              ],
            ),
            Row(
              children: [
                Obx(() => Radio(
                    value: "English",
                    groupValue: mLan.value,
                    onChanged: (lan) async {
                      mLan.value = lan.toString();
                      saveStoreLan(lan.toString());
                    })),
                const Text("English"),
              ],
            )
          ],
        ),
        const Divider(
          height: 1.0,
          indent: 5,
          endIndent: 5,
          color: Colors.black,
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child:
                  Center(child: Text(getLan() == 1 ? "Export data:" : "数据导出：")),
            ),
            Expanded(
              flex: 7,
              child: Center(
                child: Obx(() => Slider(
                    label: getLan() == 1
                        ? "Export Data Count:${mExportCount.toInt()}"
                        : "导出点数量：${mExportCount.toInt()}",
                    value: mExportCount.value,
                    max: mMaxCount.toDouble(),
                    divisions: 50,
                    onChanged: (double value) {
                      mExportCount.value = value;
                    })),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Obx(() => GFButton(
                      textStyle: TextStyle(fontFamily: 'NotoSansSC'),
                      onPressed: () async {
                        String? selectedDirectory =
                            await FilePicker.platform.getDirectoryPath();

                        if (selectedDirectory == null) {
                          // User canceled the picker
                        } else {
                          DateTime now = DateTime.now();
                          String formattedDate =
                              "/${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}_${now.second}_usbmag_export_data.txt";
                          mExportPath.value = selectedDirectory + formattedDate;
                        }
                      },
                      text: getLan() == 1 ? "Export Path" : "导出路径",
                    )),
              ),
            ),
            Expanded(flex: 7, child: Obx(() => Text(mExportPath.value)))
          ],
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Obx(() => GFButton(
                      textStyle: TextStyle(fontFamily: 'NotoSansSC'),
                      onPressed: () async {
                        if (mExportPath.value == "") {
                          Get.snackbar(
                              getLan() == 1 ? "Warning" : "警告",
                              getLan() == 1
                                  ? "Select Export Path First!"
                                  : "请先选择导出路径",
                              snackPosition: SnackPosition.BOTTOM);
                          return;
                        }

                        File f = File(mExportPath.value);
                        DateTime now = DateTime.now();
                        String exportStr = "";
                        exportStr +=
                            "${now.year}_${now.month}_${now.day}_${now.hour}_${now.minute}_${now.second}\n";
                        exportStr += "data count:${mExportCount.toInt()}\n\n";
                        // Write the file
                        int oec = mExportCount.toInt();
                        int ec = 0;
                        for (var magData in mMagChartData) {
                          ec++;
                          if (ec > oec) {
                            break;
                          }
                          if (mSingleOrThree.value == 1) {
                            exportStr +=
                                "RD ${magData.mTime},${magData.mX},${magData.mY},${magData.mZ}\n";
                          }
                          if (mSingleOrThree.value == 0) {
                            exportStr += "RD ${magData.mTime},${magData.mX}\n";
                          }
                        }
                        await f.writeAsString(exportStr, flush: true);

                        Get.snackbar(getLan() == 1 ? "Success" : "成功",
                            getLan() == 1 ? "Export Finish" : "导出完成",
                            snackPosition: SnackPosition.BOTTOM);
                      },
                      text: getLan() == 1 ? "Export" : "导出",
                    )),
              ),
            ),
            const Spacer(
              flex: 7,
            )
          ],
        ),
      ],
    );
  }

  Future<void> getStoreLan() async {
    final prefs = await SharedPreferences.getInstance();
    String? lan = prefs.getString('language');
    if (lan != null) {
      mLan.value = lan;
    }
  }

  void saveStoreLan(String lan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lan);
  }

  void handleRcData(String data) {
    mMainMsg += data;
    if (mCurCmd == "RC") {
      var rcValue = [];
      var rcs = <CMagData>[];
      do {
        rcValue = parseRc();
        if (rcValue.isNotEmpty) {
          CMagData md =
              CMagData(rcValue[0], rcValue[1], rcValue[2], rcValue[3]);
          updateRc(md);
          rcs.add(md);
        }
      } while (rcValue.isNotEmpty);

      if (rcs.isNotEmpty) {
        mValX.value = rcs[rcs.length - 1].mX.toString();
        mValY.value = rcs[rcs.length - 1].mY.toString();
        mValZ.value = rcs[rcs.length - 1].mZ.toString();
      }
    }
  }

  void handleVcData(String data) {
    mCalMsg += data;
    if (mCurCmd == "VC") {
      var rvValue = [];
      do {
        rvValue = parseVc();
        if (rvValue.isNotEmpty) {
          if (mSingleOrThree.value == 1) {
            if (mCalibrateDir.value == "X") {
              rvValue = [rvValue[0], rvValue[1]];
            }
            if (mCalibrateDir.value == "Y") {
              rvValue = [rvValue[0], rvValue[2]];
            }
            if (mCalibrateDir.value == "Z") {
              rvValue = [rvValue[0], rvValue[3]];
            }
          }

          if (rvValue[1] > mPosVol.value) {
            mPosVol.value = rvValue[1];
          }
          if (rvValue[1] < mNegVol.value) {
            mNegVol.value = rvValue[1];
          }

          mOffsetVol.value = (mPosVol.value + mNegVol.value) / 2.0;
          mSensitive.value =
              (mPosVol.value - mNegVol.value) / mParam / 2.0 * 1000.0;

          updateRv(CMagRvData(rvValue[0], rvValue[1]));
        }
      } while (rvValue.isNotEmpty);
    }
  }

  void handleCmdData(String data) {
    mCmdRevText.value += data;

    if (mCmdRevText.value.length > 6000) {
      mCmdRevText.value =
          mCmdRevText.value.substring(mCmdRevText.value.length - 6000);
    }
    if (mScrollController.hasClients) {
      mScrollController.jumpTo(mScrollController.position.maxScrollExtent);
    }
  }

  void updateRc(CMagData md) {
    mMagChartData.add(md);
    if (mMagChartData.length > mMaxCount) {
      mMagChartData.removeAt(0);

      mChartSeriesControllerX?.updateDataSource(
        addedDataIndex: mMagChartData.length - 1,
        removedDataIndex: 0,
      );
      mChartSeriesControllerY?.updateDataSource(
        addedDataIndex: mMagChartData.length - 1,
        removedDataIndex: 0,
      );
      mChartSeriesControllerZ?.updateDataSource(
        addedDataIndex: mMagChartData.length - 1,
        removedDataIndex: 0,
      );
    } else {
      mChartSeriesControllerX?.updateDataSource(
        addedDataIndex: mMagChartData.length - 1,
      );
      mChartSeriesControllerY?.updateDataSource(
        addedDataIndex: mMagChartData.length - 1,
      );
      mChartSeriesControllerZ?.updateDataSource(
        addedDataIndex: mMagChartData.length - 1,
      );
    }
  }

  void clearChartDataRC() {
    if (mMagChartData.isEmpty) return;

    var ri = <int>[];
    for (int i = 0; i < mMagChartData.length; i++) {
      ri.add(i);
    }
    mMagChartData.clear();

    mChartSeriesControllerX?.updateDataSource(
        removedDataIndexes: ri, updatedDataIndexes: ri);
    mChartSeriesControllerY?.updateDataSource(
        removedDataIndexes: ri, updatedDataIndexes: ri);
    mChartSeriesControllerZ?.updateDataSource(
        removedDataIndexes: ri, updatedDataIndexes: ri);
  }

  void clearChartDataVC() {
    if (mMagRvChartData.isEmpty) return;

    var ri = <int>[];
    for (int i = 0; i < mMagRvChartData.length; i++) {
      ri.add(i);
    }
    mMagRvChartData.clear();

    mChartSeriesControllerRV?.updateDataSource(
        removedDataIndexes: ri, updatedDataIndexes: ri);
  }

  void updateRv(CMagRvData md) {
    mMagRvChartData.add(md);
    if (mMagRvChartData.length > mMaxCount) {
      mMagRvChartData.removeAt(0);
      mChartSeriesControllerRV?.updateDataSource(
        addedDataIndex: mMagRvChartData.length - 1,
        removedDataIndex: 0,
      );
    } else {
      mChartSeriesControllerRV?.updateDataSource(
        addedDataIndex: mMagRvChartData.length - 1,
      );
    }
  }

  List parseVc() {
    if (mSingleOrThree.value == 1) {
      int i = mCalMsg.indexOf("RV");
      if (i == -1) {
        return [];
      }

      int k = mCalMsg.indexOf("RV", i + 1);
      if (k == -1) {
        return [];
      }

      String tarDataStr = mCalMsg.substring(i, k);
      tarDataStr = tarDataStr.replaceAll(RegExp("\r|\n"), "");
      tarDataStr = tarDataStr.trim();

      int d1 = tarDataStr.indexOf(',');
      if (d1 == -1) {
        return [];
      }
      int d2 = tarDataStr.indexOf(',', d1 + 1);
      if (d2 == -1) {
        return [];
      }
      int d3 = tarDataStr.indexOf(',', d2 + 1);
      if (d3 == -1) {
        return [];
      }

      double? tv = double.tryParse(tarDataStr.substring(3, d1));
      double? v1 = double.tryParse(tarDataStr.substring(d1 + 1, d2));
      double? v2 = double.tryParse(tarDataStr.substring(d2 + 1, d3));
      double? v3 = double.tryParse(tarDataStr.substring(d3 + 1));

      if (tv == null || v1 == null || v2 == null || v3 == null) {
        mMainMsg = "";
        return [];
      }
      mCalMsg = mCalMsg.substring(k);

      return [tv, v1, v2, v3];
    }

    if (mSingleOrThree.value == 0) {
      int i = mCalMsg.indexOf("RV");
      if (i == -1) {
        return [];
      }

      int k = mCalMsg.indexOf("RV", i + 1);
      if (k == -1) {
        return [];
      }

      String tarDataStr = mCalMsg.substring(i, k);
      tarDataStr = tarDataStr.replaceAll(RegExp("\r|\n"), "");
      tarDataStr = tarDataStr.trim();

      int d1 = tarDataStr.indexOf(',');
      if (d1 == -1) {
        return [];
      }

      double? tv = double.tryParse(tarDataStr.substring(3, d1));
      double? v1 = double.tryParse(tarDataStr.substring(d1 + 1));

      if (tv == null || v1 == null) {
        mCalMsg = "";
        return [];
      }
      mCalMsg = mCalMsg.substring(k);

      return [tv, v1, 0.0, 0.0];
    }

    return [];
  }

  List parseRc() {
    if (mSingleOrThree.value == 1) {
      int i = mMainMsg.indexOf("RD");
      if (i == -1) {
        return [];
      }

      int k = mMainMsg.indexOf("RD", i + 1);
      if (k == -1) {
        return [];
      }

      String tarDataStr = mMainMsg.substring(i, k);
      tarDataStr = tarDataStr.replaceAll(RegExp("\r|\n"), "");
      tarDataStr = tarDataStr.trim();

      int d1 = tarDataStr.indexOf(',');
      if (d1 == -1) {
        return [];
      }
      int d2 = tarDataStr.indexOf(',', d1 + 1);
      if (d2 == -1) {
        return [];
      }
      int d3 = tarDataStr.indexOf(',', d2 + 1);
      if (d3 == -1) {
        return [];
      }

      double? tv = double.tryParse(tarDataStr.substring(3, d1));
      double? v1 = double.tryParse(tarDataStr.substring(d1 + 1, d2));
      double? v2 = double.tryParse(tarDataStr.substring(d2 + 1, d3));
      double? v3 = double.tryParse(tarDataStr.substring(d3 + 1));

      if (tv == null || v1 == null || v2 == null || v3 == null) {
        mMainMsg = "";
        return [];
      }

      mMainMsg = mMainMsg.substring(k);

      return [tv, v1, v2, v3];
    }

    if (mSingleOrThree.value == 0) {
      int i = mMainMsg.indexOf("RD");
      if (i == -1) {
        return [];
      }

      int k = mMainMsg.indexOf("RD", i + 1);
      if (k == -1) {
        return [];
      }

      String tarDataStr = mMainMsg.substring(i, k);
      tarDataStr = tarDataStr.replaceAll(RegExp("\r|\n"), "");
      tarDataStr = tarDataStr.trim();

      int d1 = tarDataStr.indexOf(',');
      if (d1 == -1) {
        return [];
      }

      double? tv = double.tryParse(tarDataStr.substring(3, d1));
      double? v1 = double.tryParse(tarDataStr.substring(d1 + 1));
      if (tv == null || v1 == null) {
        mMainMsg = "";
        return [];
      }
      mMainMsg = mMainMsg.substring(k);

      return [tv, v1, 0.0, 0.0];
    }

    return [];
  }

  void checkSingle() {
    if (mSingleOrThreeFirstData.startsWith("MDTUSBMAG") &&
        mSingleOrThreeFirstData.length >= 10) {
      if (mSingleOrThreeFirstData[9] == '3') {
        mSingleOrThreeFirstData = "";
        mSingleOrThree.value = 1;
        return;
      }
      if (mSingleOrThreeFirstData[9] == '1') {
        mSingleOrThreeFirstData = "";
        mSingleOrThree.value = 0;
        return;
      }
    } else {
      int i = mSingleOrThreeFirstData.indexOf("RD");
      if (i == -1) {
        mSingleOrThreeFirstData = "";
        return;
      }

      int k = mSingleOrThreeFirstData.indexOf(",", i);
      if (k == -1) {
        mSingleOrThree.value = 0;
        mSingleOrThreeFirstData = "";
      } else {
        mSingleOrThree.value = 1;
        mSingleOrThreeFirstData = "";
      }
    }
  }
}

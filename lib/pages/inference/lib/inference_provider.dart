import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';

class InferenceProvider extends ChangeNotifier {
  late ReceivePort _receivePort;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  bool inProgress = false;
  late final Clasifier _clasifier;

  InferenceProvider() {
    startIsolate();
  }

  Future startIsolate() async {
    inProgress = true;
    // notifyListeners();
    _clasifier = Clasifier();
    await _clasifier.initInterpreter();

    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, _receivePort.sendPort,
        debugName: "inferenceIsolate");
    _receivePort.listen((msg) => _digestResults(msg));
    _receivePort.sendPort
        .send(IsolateData(null, _clasifier.interpreter!.address));
    inProgress = false;
    // notifyListeners();
    // _isolate = await Isolate
  }

  static void entryPoint(SendPort sendPort) {
    ReceivePort _isolateReceivePort = ReceivePort();
    sendPort.send(_isolateReceivePort.sendPort);
    Clasifier clasifier = Clasifier();
    clasifier.initImageProcessor();
    _isolateReceivePort.listen((message) async {
      if (message is IsolateData) {
        if (clasifier.interpreter == null ||
            clasifier.interpreter!.address != message.interpreterAdress) {
          clasifier.loadInterpreterFromAdress(message.interpreterAdress);
        }
        if (message.cameraImage != null && clasifier.interpreter != null) {
          var res = await clasifier.interpret(message.cameraImage!);
          sendPort.send(res);
        }
      }
    });
  }

  inference(CameraImage cameraImage) {
    print('new image');
    // if (inProgress) {
    //   return;
    // }
    inProgress = true;
    // notifyListeners();
    if (_isolateSendPort == null) {
      return;
    }

    _isolateSendPort!
        .send(IsolateData(cameraImage, _clasifier.interpreter!.address));
  }

  _digestResults(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
    } else {
      print(message);
    }
    inProgress = false;
    // notifyListeners();
  }

  stop() {
    if (_isolate != null) {
      _isolate!.kill();
    }
  }
}

class IsolateData {
  final CameraImage? cameraImage;
  final int interpreterAdress;

  IsolateData(this.cameraImage, this.interpreterAdress);
}

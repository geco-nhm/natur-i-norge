import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/inference/lib/tools.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Clasifier {
  final DEBUG_NAME = 'InferenceProvider';
  Interpreter? _interpreter;
  late final ImageProcessor _imageProcessor;
  final ImageUtils _imageUtils = ImageUtils();
  late List<List<int>> _outputShapes;

  /// Types of output tensors
  late List<TfLiteType> _outputTypes;

  Interpreter? get interpreter => _interpreter;

  Future initInterpreter() async {
    var interpreterOptions;
    if (Platform.isAndroid) {
      final gpuDelegateV2 = GpuDelegateV2(
          options: GpuDelegateOptionsV2(
        isPrecisionLossAllowed: false,
        inferencePreference: TfLiteGpuInferenceUsage.preferenceSustainSpeed,
        inferencePriority1: TfLiteGpuInferencePriority.maxPrecision,
        inferencePriority2: TfLiteGpuInferencePriority.auto,
        inferencePriority3: TfLiteGpuInferencePriority.auto,
      ));

      interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegateV2);
    } else if (Platform.isIOS) {
      final gpuDelegate = GpuDelegate(
        options: GpuDelegateOptions(
            allowPrecisionLoss: false,
            waitType: TFLGpuDelegateWaitType.active,
            enableQuantization: true),
      );
      interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegate);
    } else {
      interpreterOptions = InterpreterOptions()..threads = 4;
      // throw Exception('Not supported platform');
    }
    _interpreter = await Interpreter.fromAsset(
        "lite-model_aiy_vision_classifier_plants_V1_3.tflite",
        options: interpreterOptions);
    initOuputShapes(_interpreter!);
  }

  initImageProcessor() {
    _imageProcessor = ImageProcessorBuilder()
        .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
        .build();
  }

  loadInterpreterFromAdress(int interpreterAdress) {
    _interpreter = Interpreter.fromAddress(interpreterAdress);
    initOuputShapes(_interpreter!);
  }

  initOuputShapes(Interpreter interpreter) {
    var outputTensors = interpreter.getOutputTensors();
    // interpreter.getOutputIndex(opName)
    _outputShapes = [];
    _outputTypes = [];
    outputTensors.forEach((tensor) {
      _outputShapes.add(tensor.shape);
      _outputTypes.add(tensor.type);
    });
    print(_outputShapes);
    print(_outputTypes);
  }

  Future interpret(CameraImage cameraImage) async {
    if (cameraImage.planes.isEmpty) {
      return;
    }
    var image = ImageUtils.convertCameraImage(cameraImage);
    TensorImage tensorImage = TensorImage.fromImage(image);
    tensorImage = _imageProcessor.process(tensorImage);
    var output;
    _interpreter!.run(tensorImage, output);
    return output;
  }

  static void entryPoint(SendPort sendPort) {
    Clasifier clasifier = Clasifier();
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((cameraImage) {
      clasifier.interpret(cameraImage);
    });
  }
}

// class IsolateData {
//   late CameraImage cameraImage;
//   late int interpreterAddress;
//   late List<String> labels;
//   SendPort? responsePort;

//   IsolateData(
//     this.cameraImage,
//     this.interpreterAddress,
//     this.labels,
//   );
// }

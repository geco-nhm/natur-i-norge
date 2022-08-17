import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/inference/lib/tools.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier {
  bool isProcessing = false;
  final DEBUG_NAME = 'InferenceProvider';
  Interpreter? _interpreter;
  late final ImageProcessor _imageProcessor;
  final ImageUtils _imageUtils = ImageUtils();
  // late List<List<int>> _outputShapes;
  late List<Tensor> _inputTensors;
  late List<Tensor> _outputTensors;
  TensorBuffer probabilityBuffer =
      TensorBuffer.createFixedSize(<int>[1, 1230], TfLiteType.float32);

  /// Types of output tensors
  // late List<TfLiteType> _outputTypes;

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
    _interpreter = await Interpreter.fromAsset("model_1.tflite",
        options: interpreterOptions);
    _inputTensors = _interpreter!.getInputTensors();
    _outputTensors = _interpreter!.getOutputTensors();
    print(_inputTensors);
    print(_outputTensors);
  }

  initImageProcessor() {
    _imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(720, 720))
        // .add(NormalizeOp(mean, stddev))
        .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
        .build();
  }

  loadInterpreterFromAddress(int interpreterAdress) {
    _interpreter = Interpreter.fromAddress(interpreterAdress);
  }

  Future interpret(CameraImage cameraImage) async {
    if (cameraImage.planes.isEmpty) {
      return;
    }
    isProcessing = true;
    var image = ImageUtils.convertCameraImage(cameraImage);
    TensorImage tensorImage = TensorImage.fromImage(image);
    var processedTensorImage = _imageProcessor.process(tensorImage);
    try {
      _interpreter!.run(processedTensorImage.buffer, probabilityBuffer.buffer);
    } catch (e) {
      print('Unable to interpret: ${e.toString()}');
    }
    isProcessing = false;
    return probabilityBuffer;
  }

  static void entryPoint(SendPort sendPort) {
    Classifier classifier = Classifier();
    ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((cameraImage) {
      classifier.interpret(cameraImage);
    });
  }

  stop() {
    // _interpreter!.close();
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

import 'dart:async';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class InferenceProvider extends ChangeNotifier {
  late ReceivePort _receivePort;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  bool _inProgress = false;
  late Classifier _classifier;
  late List<String> labels;
  var _history = List<Map<String, double>>.empty(growable: true);
  bool _wasHistoryEmpty = true;
  double _threshold = 0.90;
  int _bufferSize = 50;
  var _approvedSpecies = List<ApprovedSpecie>.empty(growable: true);
  var _predictedNinTypes = List<PredictedType>.empty(growable: true);
  // var _predictedTypes = List<List<>>.empty();
  var _predictedSpecies = List<PredictedSpecie>.empty(growable: true);
  final Locale _locale;

  InferenceProvider(this._locale) {
    startIsolate();
  }

  @override
  void dispose() {
    _isolate?.kill();
    super.dispose();
  }

  Future startIsolate() async {
    _inProgress = true;
    notifyListeners();
    _classifier = Classifier();
    await _classifier.initInterpreter();
    labels = await FileUtil.loadLabels("assets/labels.txt");
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(entryPoint, _receivePort.sendPort,
        debugName: "inferenceIsolate");
    _receivePort.listen((msg) => _digestResults(msg));
    _receivePort.sendPort
        .send(IsolateData(null, _classifier.interpreter!.address));

    _inProgress = false;
    notifyListeners();
    // _isolate = await Isolate
  }

  clearResults() {
    _history.clear();
    _approvedSpecies.clear();
    _predictedSpecies.clear();
    _predictedNinTypes.clear();
  }

  resetInference() {
    clearResults();
    notifyListeners();
  }

  _calculatePredictions() async {
    if (_history.isEmpty) {
      if (_wasHistoryEmpty) {
        return;
      }
      _wasHistoryEmpty = true;
      notifyListeners();
      return;
    }
    _wasHistoryEmpty = false;
    // get most common species with from history
    final tmpSpecies = List<PredictedSpecie>.empty(growable: true);
    _predictedSpecies.clear();

    for (var key in _history[0].keys) {
      var probSum = _history
          .map((e) => e[key])
          .reduce((value, element) => value! + element!);
      var probMean = probSum! / _history.length;
      if (probMean > _threshold) {
        var specie;
        try {
          specie = await db!.getInferenceSpecieByGbifId(int.parse(key));
        } catch (e) {
          print('Unable to find $key in InferenceSpecies DB');
          continue;
        }

        var res = PredictedSpecie(specie, probMean);

        tmpSpecies.add(res);
      }
    }

    tmpSpecies.sort(((a, b) => b.probability.compareTo(a.probability)));
    _predictedSpecies = tmpSpecies;

    _history.clear();
    // print(found_species);

    notifyListeners();
  }

  calculateNinTypes() async {
    var mints = List<String>.empty(growable: true);
    for (var element in _approvedSpecies) {
      var tmpMints =
          element.inferenceTypes.map<String>((e) => e.minorTypeScaledId!);
      mints.addAll(tmpMints);
    }
    final tmpPredictedNinTypes = List<PredictedType>.empty(growable: true);
    var uniqueMints = Set.from(mints);
    for (var uMint in uniqueMints) {
      var count = mints.where((e) => e == uMint).length;
      var minorTypeScaled = await db!.getMinorTypeScaledById(uMint);
      Detailed<NinMinorTypeScaledData> detailedMinorTypeScaled =
          await Detailed<NinMinorTypeScaledData>()
              .initialize(minorTypeScaled[0], _locale);
      tmpPredictedNinTypes.add(PredictedType(detailedMinorTypeScaled, count));
    }
    tmpPredictedNinTypes.sort(((a, b) => b.count.compareTo(a.count)));
    _predictedNinTypes = tmpPredictedNinTypes;
    notifyListeners();
  }

  static void entryPoint(SendPort sendPort) {
    ReceivePort _isolateReceivePort = ReceivePort();
    sendPort.send(_isolateReceivePort.sendPort);
    Classifier classifier = Classifier();
    classifier.initImageProcessor();
    _isolateReceivePort.listen((message) async {
      if (message is IsolateData) {
        if (classifier.interpreter == null ||
            classifier.interpreter!.address != message.interpreterAddress) {
          classifier.loadInterpreterFromAddress(message.interpreterAddress);
        }
        if (message.cameraImage != null &&
            classifier.interpreter != null &&
            !classifier.isProcessing) {
          var res = await classifier.interpret(message.cameraImage!);
          // print(res);
          sendPort.send(res);
        }
      }
    });
  }

  inference(CameraImage cameraImage) {
    _inProgress = true;
    notifyListeners();
    if (_isolateSendPort == null) {
      return;
    }

    _isolateSendPort!
        .send(IsolateData(cameraImage, _classifier.interpreter!.address));
  }

  _digestResults(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
    } else if (message is IsolateData) {
    } else if (message is TensorBufferFloat) {
      var prediction = message;
      TensorLabel tensorLabel = TensorLabel.fromList(labels, prediction);
      _history.add(tensorLabel.getMapWithFloatValue());
      print('prediction added to history');
      if (_history.length >= _bufferSize) {
        _calculatePredictions();
      }

      // print('digest result: ${tensorLabel.getMapWithFloatValue()}');
    }
    _inProgress = false;
    notifyListeners();
    // notifyListeners();
  }

  pause() {
    _history.clear();
  }

  bool isSpecieApproved(PredictedSpecie predictedSpecie) {
    return _approvedSpecies
        .map((e) => e.inferenceSpecie.gbifId)
        .contains(predictedSpecie.specie.gbifId);
  }

  approveSpecie(PredictedSpecie predictedSpecie) async {
    var inferenceSpecies =
        await db!.getInferenceTypeByGbifId(predictedSpecie.specie.gbifId);
    _approvedSpecies
        .add(ApprovedSpecie(predictedSpecie.specie, inferenceSpecies));
    calculateNinTypes();
  }

  removeApprovedSpecie(int gbifId) {
    _approvedSpecies.removeWhere((e) => e.inferenceSpecie.gbifId == gbifId);
    calculateNinTypes();
  }

  double get predictionProgress => _history.length / _bufferSize;

  List<PredictedType> get predictedTypes => _predictedNinTypes;
  List<PredictedSpecie> get predictedSpecies => _predictedSpecies;
  List<ApprovedSpecie> get approvedSpecies => _approvedSpecies;
  bool get inProgress => _inProgress;
  double get getThreshold => _threshold;
  set setThreshold(double val) {
    _threshold = val;
    notifyListeners();
  }

  int get getBufferSize => _bufferSize;
  set setBufferSize(int val) {
    _bufferSize = val;
    notifyListeners();
  }
}

class IsolateData {
  final CameraImage? cameraImage;
  final int interpreterAddress;

  IsolateData(this.cameraImage, this.interpreterAddress);
}

class PredictedSpecie {
  final NinInferenceSpecie specie;
  final double probability;

  PredictedSpecie(this.specie, this.probability);
}

class PredictedType {
  final Detailed<NinMinorTypeScaledData> minorTypeScaled;
  final int count;

  PredictedType(this.minorTypeScaled, this.count);
}

class ApprovedSpecie {
  final NinInferenceSpecie inferenceSpecie;
  final List<NinInferenceType> inferenceTypes;

  ApprovedSpecie(this.inferenceSpecie, this.inferenceTypes);
}

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class InferenceProvider extends ChangeNotifier {
  bool isInitialised = false;
  late ReceivePort _receivePort;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  bool _inProgress = false;
  late final Classifier _classifier;
  late List<String> labels;
  var history = List<Map<String, double>>.empty(growable: true);
  bool wasHistoryEmpty = true;
  Timer? timer;
  double _threshold = 0.90;
  var _allFoundSpeciesIds = Set<FoundSpecie>();
  var _predictedNinTypes = List<PredictedType>.empty(growable: true);
  // var _predictedTypes = List<List<>>.empty();
  var _recentSpecies = List<PredictedSpecie>.empty(growable: true);
  InferenceProvider() {
    startIsolate();
    startTimer();
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
    history.clear();
    _allFoundSpeciesIds.clear();
    _recentSpecies.clear();
    _predictedNinTypes.clear();
  }

  resetInference() {
    clearResults();
    notifyListeners();
  }

  _calculateResults() async {
    if (history.isEmpty) {
      if (wasHistoryEmpty) {
        return;
      }
      wasHistoryEmpty = true;
      notifyListeners();
      return;
    }
    wasHistoryEmpty = false;
    // get most common species with from history
    final tmp_species = List<PredictedSpecie>.empty(growable: true);
    _recentSpecies.clear();

    for (var key in history[0].keys) {
      var prob_sum = history
          .map((e) => e[key])
          .reduce((value, element) => value! + element!);
      var prob_mean = prob_sum! / history.length;
      if (prob_mean > _threshold) {
        var specie;
        try {
          specie = await db!.getOneInferenceSpecieByGbifId(int.parse(key));
        } catch (e) {
          print('Unable to find $key in InferenceSpecies DB');
          continue;
        }

        var res = PredictedSpecie(specie, prob_mean);

        tmp_species.add(res);
      }
    }
    tmp_species.sort(((a, b) => b.probability.compareTo(a.probability)));
    _recentSpecies = tmp_species;

    if (tmp_species.isNotEmpty) {
      if (_allFoundSpeciesIds
          .map<int>((e) => e.minorTypeId)
          .toList()
          .contains(tmp_species[0].specie.minorTypeId)) {
        history.clear();
        notifyListeners();
        return;
      }
      var best_sp = tmp_species[0].specie;
      var best_sp_inf = await db!.getInferenceSpecieByGbifId(best_sp.gbifId!);
      _allFoundSpeciesIds.add(FoundSpecie(best_sp.gbifId!, best_sp_inf));

      var mints = List<String>.empty(growable: true);
      for (var element in _allFoundSpeciesIds) {
        var mints_tmp =
            element.inferenceSpecies.map<String>((e) => e.minorTypeId!);
        mints.addAll(mints_tmp);
      }
      final tmp_results = List<PredictedType>.empty(growable: true);
      var unique_mints = Set.from(mints);
      unique_mints.forEach((uMint) {
        var count = mints.where((e) => e == uMint).length;
        tmp_results.add(PredictedType(uMint, count));
      });
      tmp_results.sort(((a, b) => b.count.compareTo(a.count)));
      _predictedNinTypes = tmp_results;
    }

    history.clear();
    // print(found_species);

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
            classifier.interpreter!.address != message.interpreterAdress) {
          classifier.loadInterpreterFromAdress(message.interpreterAdress);
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

  startTimer() {
    timer =
        Timer.periodic(Duration(seconds: 2), (Timer t) => _calculateResults());
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
      history.add(tensorLabel.getMapWithFloatValue());
      print('prediction added to history');

      // print('digest result: ${tensorLabel.getMapWithFloatValue()}');
    }
    _inProgress = false;
    notifyListeners();
    // notifyListeners();
  }

  pause() {
    if (timer != 0) {
      timer!.cancel();
    }
  }

  stop() {
    if (_isolate != null) {
      _isolate!.kill();
    }

    _classifier.stop();
  }

  List<PredictedType> get predictedTypes => _predictedNinTypes;
  List<PredictedSpecie> get predictedSpecies => _recentSpecies;
  bool get inProgress => _inProgress;
  double get getThreshold => _threshold;
  set setThreshold(double val) {
    _threshold = val;
    notifyListeners();
  }
}

class IsolateData {
  final CameraImage? cameraImage;
  final int interpreterAdress;

  IsolateData(this.cameraImage, this.interpreterAdress);
}

class PredictedSpecie {
  final NinInferenceSpecie specie;
  final double probability;

  PredictedSpecie(this.specie, this.probability);
}

class PredictedType {
  final String minorTypeId;
  final int count;

  PredictedType(this.minorTypeId, this.count);
}

class FoundSpecie {
  final int minorTypeId;
  final List<NinInferenceSpecie> inferenceSpecies;

  FoundSpecie(this.minorTypeId, this.inferenceSpecies);
}

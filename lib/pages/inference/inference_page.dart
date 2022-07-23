import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';
import 'package:naturinorge_guide/pages/inference/lib/inference_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';

class InferencePage extends StatefulWidget {
  const InferencePage({Key? key}) : super(key: key);

  @override
  State<InferencePage> createState() => _InferencePageState();
}

class _InferencePageState extends State<InferencePage> {
  late CameraController controller;
  bool predicting = false;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[0],
      ResolutionPreset.low,
      // imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      } else {
        var inferenceProvider =
            Provider.of<InferenceProvider>(context, listen: false);

        controller
            .startImageStream((image) => inferenceProvider.inference(image));
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: CameraPreview(controller),
    );
  }
}

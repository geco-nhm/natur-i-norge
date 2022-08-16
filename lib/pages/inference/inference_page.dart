import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';
import 'package:naturinorge_guide/pages/inference/lib/inference_provider.dart';
import 'package:naturinorge_guide/pages/inference/lib/predicted_widget.dart';
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
  late InferenceProvider inferenceProvider;
  bool isRecording = false;
  bool isInitialized = false;

  @override
  void didChangeDependencies() {
    inferenceProvider = Provider.of<InferenceProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
      // imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    controller.initialize().then((_) {
      controller.startImageStream(imageStream);
      setState(() {
        isInitialized = true;
      });
      // inferenceProvider.resetInference();
    });
  }

  toggleRecording() {
    setState(() {
      isRecording = !isRecording;
    });
  }

  imageStream(CameraImage image) {
    if (!inferenceProvider.inProgress && isRecording) {
      return inferenceProvider.inference(image);
    }
  }

  @override
  void dispose() {
    inferenceProvider.timer?.cancel();
    inferenceProvider.clearResults();
    // controller.stopImageStream();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Inference'),
        actions: [
          IconButton(
              onPressed: () =>
                  Provider.of<InferenceProvider>(context, listen: false)
                      .resetInference(),
              icon: Icon(Icons.refresh))
        ],
      ),
      body: Column(mainAxisSize: MainAxisSize.max, children: [
        Expanded(child: CameraPreview(controller)),
        Center(
            child: Text(Provider.of<InferenceProvider>(context)
                .getThreshold
                .toString())),
        Slider(
            label: Provider.of<InferenceProvider>(context)
                .getThreshold
                .toStringAsPrecision(2),
            value: Provider.of<InferenceProvider>(context).getThreshold,
            onChanged: (val) =>
                Provider.of<InferenceProvider>(context, listen: false)
                    .setThreshold = val),
        SizedBox(
            height: 300,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PredictedSpeciesWidget(),
                PredictedTypesWidget(),
              ],
            )),
      ]),
      floatingActionButton: isInitialized
          ? FloatingActionButton.large(
              onPressed: () => toggleRecording(),
              backgroundColor: isRecording ? Colors.red : Colors.green,
              child: isRecording ? Icon(Icons.stop) : Icon(Icons.play_arrow),
            )
          : null,
    );
  }
}

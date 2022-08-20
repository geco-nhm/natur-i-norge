import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';
import 'package:naturinorge_guide/pages/inference/lib/inference_provider.dart';
import 'package:naturinorge_guide/pages/inference/lib/predicted_widget.dart';
import 'package:naturinorge_guide/pages/inference/lib/tools.dart';
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
  bool isRecording = true;
  bool isInitialized = false;
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);
  var textEditingController = TextEditingController();

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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
          body: SafeArea(
            child: Column(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: AspectRatio(
                          aspectRatio: 720 / 1280,
                          child: CameraPreview(controller)),
                    ),
                    Expanded(flex: 1, child: PredictedTypesWidget()),
                  ],
                ),
              ),
              Divider(),
              // LinearProgressIndicator(
              //   value: Provider.of<InferenceProvider>(context).predictionProgress,
              // ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                        enableDrag: true,
                        context: context,
                        builder: ((context) {
                          var speciesListFiltered =
                              Provider.of<InferenceProvider>(context)
                                  .speciesListFiltered;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText:
                                          "Search for species in Norwegian or Latin",
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          Provider.of<InferenceProvider>(
                                                  context,
                                                  listen: false)
                                              .filterSpecies('');
                                          textEditingController.clear();
                                        },
                                        icon: Icon(Icons.clear),
                                      ),
                                    ),
                                    controller: textEditingController,
                                    onChanged: (value) =>
                                        Provider.of<InferenceProvider>(context,
                                                listen: false)
                                            .filterSpecies(value)),
                              ),
                              if (speciesListFiltered.isNotEmpty)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListView.builder(
                                        itemCount: speciesListFiltered.length,
                                        itemBuilder: ((context, index) =>
                                            ListTile(
                                              onTap: () => Provider.of<
                                                          InferenceProvider>(
                                                      context,
                                                      listen: false)
                                                  .approveSpecie(
                                                speciesListFiltered[index],
                                              ),
                                              title: Text(
                                                  speciesListFiltered[index]
                                                      .nameNb!),
                                              subtitle: Text(
                                                  speciesListFiltered[index]
                                                      .nameLatin!),
                                              trailing: Provider.of<
                                                              InferenceProvider>(
                                                          context)
                                                      .approvedSpecies
                                                      .map((e) => e
                                                          .inferenceSpecie
                                                          .gbifId)
                                                      .contains(
                                                          speciesListFiltered[
                                                                  index]
                                                              .gbifId)
                                                  ? Icon(Icons.check)
                                                  : null,
                                            ))),
                                  ),
                                )
                            ],
                          );
                        })),
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        Text('Add specie manually'),
                      ],
                    )),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SuggestedSpeciesWidget(),
                    VerticalDivider(),
                    ApprovedSpeciesWidget(),
                  ],
                ),
              ),
              Divider(),
              Row(
                children: [
                  Column(
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: Text(
                      //       '${Provider.of<InferenceProvider>(context).getBufferSize.toStringAsFixed(0)} frames'),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                            '${(Provider.of<InferenceProvider>(context).getThreshold * 100).toStringAsFixed(0)} %'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        // Slider(
                        //     min: 1.0,
                        //     max: 100.0,
                        //     value: Provider.of<InferenceProvider>(context)
                        //         .getBufferSize
                        //         .toDouble(),
                        //     onChanged: (val) => Provider.of<InferenceProvider>(
                        //             context,
                        //             listen: false)
                        //         .setBufferSize = val.toInt()),
                        Slider(
                            value: Provider.of<InferenceProvider>(context)
                                .getThreshold,
                            onChanged: (val) => Provider.of<InferenceProvider>(
                                    context,
                                    listen: false)
                                .setThreshold = val),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                  )
                ],
              )
            ]),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniEndFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () => toggleRecording(),
            backgroundColor:
                isRecording ? Colors.red.shade400 : Colors.green.shade400,
            child: isRecording ? Icon(Icons.stop) : Icon(Icons.start),
          )),
    );
  }
}

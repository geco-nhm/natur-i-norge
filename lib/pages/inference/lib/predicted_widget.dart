import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/inference/lib/inference_provider.dart';
import 'package:provider/provider.dart';

class SuggestedSpeciesWidget extends StatelessWidget {
  const SuggestedSpeciesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var predictedSpecies =
        Provider.of<InferenceProvider>(context).suggestedSpecies;

    if (predictedSpecies.isEmpty) {
      return Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'No species recognized...',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
          itemCount: predictedSpecies.length,
          // separatorBuilder: (context, index) => Divider(
          //       color: Colors.black,
          //     ),
          itemBuilder: (ctx, idx) {
            return Material(
              elevation: 3,
              child: Column(
                children: [
                  // LinearProgressIndicator(
                  //   value: predictedSpecies[idx].probability,
                  // ),
                  ListTile(
                    onTap: () =>
                        Provider.of<InferenceProvider>(context, listen: false)
                            .approveSpecie(predictedSpecies[idx].specie),
                    title: Text(predictedSpecies[idx].specie.nameNb ?? ''),
                    subtitle: Text(predictedSpecies[idx].specie.nameLatin!),
                    // leading:
                    //     Text(predictedSpecies[idx].probability.toStringAsFixed(2)),
                    trailing:
                        Provider.of<InferenceProvider>(context, listen: false)
                                .isSpecieApproved(predictedSpecies[idx].specie)
                            ? Icon(Icons.check)
                            : null,
                  ),
                ],
              ),
            );
          }),
    );
  }
}

class PredictedTypesWidget extends StatelessWidget {
  const PredictedTypesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var predictedTypes = Provider.of<InferenceProvider>(context).predictedTypes;
    if (predictedTypes.isEmpty) {
      return Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Add species to get suggested types',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
        itemCount: predictedTypes.length,
        itemBuilder: (ctx, idx) {
          return ListTile(
            title: Text(predictedTypes[idx].minorTypeScaled.name!),
            subtitle:
                Text(predictedTypes[idx].minorTypeScaled.data!.id.toString()),
            leading: Text(predictedTypes[idx].count.toString()),
          );
        });
  }
}

class ApprovedSpeciesWidget extends StatelessWidget {
  const ApprovedSpeciesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var approvedSpecies =
        Provider.of<InferenceProvider>(context).approvedSpecies;
    if (approvedSpecies.isEmpty) {
      return Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Add species to get suggestions',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
          itemCount: approvedSpecies.length,
          itemBuilder: (ctx, idx) {
            return ListTile(
              title: Text(approvedSpecies[idx].inferenceSpecie.nameNb!),
              subtitle: Text(approvedSpecies[idx].inferenceSpecie.nameLatin!),
              leading: IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () =>
                    Provider.of<InferenceProvider>(context, listen: false)
                        .removeApprovedSpecie(
                            approvedSpecies[idx].inferenceSpecie.gbifId),
              ),
            );
          }),
    );
  }
}

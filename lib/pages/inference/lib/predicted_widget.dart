import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/inference/lib/inference_provider.dart';
import 'package:provider/provider.dart';

class PredictedSpeciesWidget extends StatelessWidget {
  const PredictedSpeciesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var predictedSpecies =
        Provider.of<InferenceProvider>(context).predictedSpecies;

    if (predictedSpecies.isEmpty) {
      return Container();
    }
    return Expanded(
      child: Material(
          child: ListView.builder(
              itemCount: predictedSpecies.length,
              itemBuilder: (ctx, idx) {
                return ListTile(
                  title: Text(predictedSpecies[idx].specie.nameNb ?? ''),
                  subtitle: Text(predictedSpecies[idx].specie.nameLatin!),
                  leading: Text(
                      predictedSpecies[idx].probability.toStringAsFixed(2)),
                );
              })),
    );
  }
}

class PredictedTypesWidget extends StatelessWidget {
  const PredictedTypesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var predictedTypes = Provider.of<InferenceProvider>(context).predictedTypes;
    if (predictedTypes.isEmpty) {
      return Container();
    }
    return Expanded(
      child: Material(
          child: ListView.builder(
              itemCount: predictedTypes.length,
              itemBuilder: (ctx, idx) {
                return ListTile(
                  title: Text(predictedTypes[idx].minorTypeId),
                  leading: Text(predictedTypes[idx].count.toString()),
                );
              })),
    );
  }
}

import 'dart:ui';

import 'package:naturinorge_guide/db/db_adapters.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/main.dart';

class SpecieAdapter {
  final NinMajorTypeData? majorType;
  final Locale? locale;
  final NinSpecie specie;
  late List<GadValueAdapter> gadValues;
  late List<GadModifierAdpater> gadModifiers;

  SpecieAdapter(this.specie, this.locale, this.majorType);
  Future getRelations() async {
    var gadValuesData =
        await db!.getGadValuesBySpeciesId(specie.scientificNameId, majorType!.id);
    gadValues = List<GadValueAdapter>.empty(growable: true);
    for (var gadValueData in gadValuesData) {
      var gadValue = GadValueAdapter(gadValueData, locale);
      await gadValue.getRelations();
      gadValues.add(gadValue);
    }

    gadModifiers = List<GadModifierAdpater>.empty(growable: true);
    var gadModifiersData = await db!.getGadModifiersBySpeciesId(
        specie.scientificNameId, majorType!.id);
    for (var gadModifierData in gadModifiersData) {
      var gadModifier = GadModifierAdpater(locale, gadModifierData);
      await gadModifier.getRelations();
      gadModifiers.add(gadModifier);
    }
  }
}

class GadValueAdapter {
  final Locale? locale;
  final NinGadValueData gadValue;
  late List<NinElementarySegmentCombinationData> elementarySegmentCombinations;
  late List<ElementarySegmentGroupAdapter> elementarySegmentGroupAdapters;
  GadValueAdapter(this.gadValue, this.locale);

  Future getRelations() async {
    elementarySegmentCombinations = await db!
        .getElementarySegmentCombinationsByElementarySegmentCombinationId(
            gadValue.elementarySegmentCombinationId);
    if (elementarySegmentCombinations.length == 0)
      throw Exception(
          'unable to find elementayr segment combination with id: ${gadValue.elementarySegmentCombinationId}');
    elementarySegmentGroupAdapters =
        List<ElementarySegmentGroupAdapter>.empty(growable: true);
    for (var elementarySegmentCombination in elementarySegmentCombinations) {
      var esg = ElementarySegmentGroupAdapter(
          locale, elementarySegmentCombination.elementarySegmentGroupId);
      await esg.getRelations();
      elementarySegmentGroupAdapters.add(esg);
    }
  }
}

class GadModifierAdpater {
  final Locale? locale;
  final NinGadModifierData gadModifier;
  Detailed<NinLECData>? lec;

  GadModifierAdpater(this.locale, this.gadModifier);

  Future getRelations() async {
    lec = await db!.getLecById(gadModifier.lecId, locale);
  }
}

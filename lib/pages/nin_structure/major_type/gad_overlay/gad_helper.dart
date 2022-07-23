import 'dart:ui';

import 'package:naturinorge_guide/db/db_adapters.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/gad_overlay/specie_adapter.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/axis_block.dart';
import 'package:naturinorge_guide/tools/array_tools.dart';

class GadHelper {
  final Locale? locale;
  final NinMajorTypeData? majorType;
  final AxisBlock? xAxis;
  final AxisBlock? yAxis;
  final List<AxisBlock>? zAxis;
  // dynamic finalArray;
  List<dynamic> allArrays = List<dynamic>.empty(growable: true);
  late List<int> dims;
  dynamic _meanArray;

  List<SpecieAdapter> selectedSpecies =
      List<SpecieAdapter>.empty(growable: true);

  GadHelper({this.majorType, this.locale, this.xAxis, this.yAxis, this.zAxis}) {
    _generateDims();
  }

  Future addSpecie(NinSpecie specie) async {
    var specieAdapter = SpecieAdapter(specie, locale, majorType);
    await specieAdapter.getRelations();
    if (selectedSpecies.contains(specieAdapter)) {
      print('Specie already added');
      return;
    }
    selectedSpecies.add(specieAdapter);
    var newArray = createArray(dims);
    for (var gadValue in specieAdapter.gadValues) {
      var xElem = gadValue.elementarySegmentGroupAdapters.firstWhere(
          (element) =>
              xAxis!.lecAdapter.gadElementarySegmentGroups.contains(element));
      var xCoor = xAxis!.lecAdapter.gadElementarySegmentGroups.indexOf(xElem);

      var yElem = gadValue.elementarySegmentGroupAdapters.firstWhere(
          (element) =>
              yAxis!.lecAdapter.gadElementarySegmentGroups.contains(element));
      var yCoor = yAxis!.lecAdapter.gadElementarySegmentGroups.indexOf(yElem);

      var coors = List<int>.empty(growable: true);
      for (var axis in zAxis!) {
        var zElem = gadValue.elementarySegmentGroupAdapters.firstWhere(
            (element) =>
                axis.lecAdapter.gadElementarySegmentGroups.contains(element));
        var zCoor = axis.lecAdapter.gadElementarySegmentGroups.indexOf(zElem);
        coors.add(zCoor);
      }
      coors.add(xCoor);
      coors.add(yCoor);
      newArray = addToArray(newArray, coors, gadValue.gadValue.valueM7ScaleId);
    }
    allArrays.add(newArray);
    _meanArray = _getMeanArray();
  }

  removeSpecie(NinSpecie specie) {
    var idx = selectedSpecies.indexWhere(
        (e) => e.specie.scientificNameId == specie.scientificNameId);
    selectedSpecies.removeAt(idx);
    allArrays.removeAt(idx);
    _meanArray = _getMeanArray();
  }

  _generateDims() {
    dims = List<int>.empty(growable: true);
    if (zAxis != null) {
      for (var axis in zAxis!) {
        dims.add(axis.lecAdapter.gadElementarySegmentGroups.length);
      }
    }
    dims.add(xAxis!.lecAdapter.gadElementarySegmentGroups.length);
    if (yAxis != null) {
      dims.add(yAxis!.lecAdapter.gadElementarySegmentGroups.length);
    }
  }

  dynamic _getMeanArray() {
    if (allArrays.length == 0) {
      return null;
    }
    if (allArrays.length == 1) {
      return allArrays.first;
    } else {
      var addedArrays =
          allArrays.reduce((value, element) => addArrays(value, element));
      var meanArray = divideArrayBy(addedArrays, allArrays.length.toDouble());
      return meanArray;
    }
  }

  List<dynamic>? getSlice(List<StandardSegmentAdapter> selectedZAxisSegments) {
    dynamic slice = _meanArray;
    for (var selectedStandardSegment in selectedZAxisSegments) {
      slice = slice[selectedStandardSegment.standardSegment.data!.order];
    }
    // List<List<dynamic?>>? res = slice
    //     .map<List<dynamic?>?>((e) => List<dynamic?>.from(e, growable: false))
    //     .toList();
    return slice;
  }
}

import 'dart:async';
import 'dart:ui';

import 'package:moor/moor.dart';
import 'package:naturinorge_guide/db/lazy_db_web.dart'
    if (dart.library.io) 'package:naturinorge_guide/db/lazy_db_flutter.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';

part 'nin_db.g.dart';

@UseMoor(
  // relative import for the moor file. Moor also supports `package:`
  // imports
  daos: [],
  include: {'schema.moor'},
)
class NiNDatabase extends _$NiNDatabase {
  NiNDatabase() : super(_openConnection());
  // query's definitions
  Future<List<NinMajorTypeGroupData>> get allMajorTypeGroups =>
      select(ninMajorTypeGroup).get();

  Future<List<Detailed<NinMajorTypeData>>> filteredMajorTypes(
      String? majorTypeGroupId, Locale? locale) async {
    var majorTypes = await (select(ninMajorType)
          ..where((tbl) => tbl.majorTypeGroupId.equals(majorTypeGroupId)))
        .get();
    return await Detailed<NinMajorTypeData>().fromList(majorTypes, locale);
  }

  Future<List<NinDetailData>> getDetails(
      String? detailId, Locale? locale) async {
    var res = (select(ninDetail)
      ..where((tbl) => tbl.id.equals(detailId))
      ..where((tbl) => tbl.languageId.equals(locale!.languageCode)));
    return res.get();
  }

  Future<List<NinMajorTypeLECData>> getMajorTypeLecByMajorTypeId(
      String? majorTypeId) {
    return (select(ninMajorTypeLEC)
          ..where((tbl) => tbl.majorTypeId.equals(majorTypeId)))
        .get();
  }

  Future<NinMajorTypeLECData> getMajorTypeLecByStandardSegment(
          NinStandardSegmentData standardSegment) =>
      (select(ninMajorTypeLEC)
            ..where((tbl) => tbl.id.equals(standardSegment.majorTypeLECId)))
          .getSingle();

  Future<List<NinMappingScaleData?>> getMappingScales() =>
      select(ninMappingScale).get();

  Future<NinMappingScaleData> getMappingScaleById(int id) =>
      (select(ninMappingScale)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<List<String?>> getMinorTypeScaledIdsByMajorTypeAndScale(
      NinMajorTypeData? majorType, NinMappingScaleData? mappingScale) async {
    var minorTypes = (await (select(ninMinorType)
              ..where((tbl) => tbl.majorTypeId.equals(majorType!.id)))
            .get())
        .map((e) => e.id);

    var minorTypesScaled = await (select(ninMinorTypeScaled)
          ..where((tbl) => tbl.minorTypeId.isIn(minorTypes))
          ..where((tbl) => tbl.mappingScaleId.equals(mappingScale!.id)))
        .get();
    var res = minorTypesScaled.map((e) => e.id).toSet().toList();
    return res;
  }

  Future<List<Detailed<NinMinorTypeData>>> getMinorTypesByMajorTypeScaledId(
      String? majorTypeSacledId, Locale locale) async {
    var minorTypeIds = await (select(ninMinorTypeScaled)
          ..where((tbl) => tbl.id.equals(majorTypeSacledId)))
        .get();
    var minorTypes = await (select(ninMinorType)
          ..where((tbl) => tbl.id.isIn(minorTypeIds.map((e) => e.minorTypeId))))
        .get();

    return Detailed<NinMinorTypeData>().fromList(minorTypes, locale);
  }

  Future<List<Detailed<NinStandardSegmentData>>>
      getStandardSegmentsByMajorTypeLec(
          NinMajorTypeLECData majorTypeLEC, Locale locale) async {
    var standardSegments = await (select(ninStandardSegment)
          ..where((tbl) =>
              tbl.majorTypeLECId.equals(majorTypeLEC.id) &
              isNull(tbl.order).not()))
        .get();
    return await Detailed<NinStandardSegmentData>()
        .fromList(standardSegments, locale);
  }

  Future<List<Detailed<NinStandardSegmentData>>> getStandardSegmentsByMinorType(
      NinMinorTypeData? minorType, Locale locale) async {
    var minorTypeStandardSegments = await (select(ninMinorTypeStandardSegment)
          ..where((tbl) => tbl.minorTypeId.equals(minorType!.id)))
        .get();
    var standardSegments = await (select(ninStandardSegment)
          ..where((tbl) => tbl.id
              .isIn(minorTypeStandardSegments.map((e) => e.standardSegmentId))))
        .get();
    return await Detailed<NinStandardSegmentData>()
        .fromList(standardSegments, locale);
  }

  Future<List<Detailed<NinStandardSegmentData>>> getStandardSegmentsByMajorType(
      NinMajorTypeData majorType, Locale locale) async {
    var majorTypeLec = await (select(ninMajorTypeLEC)
          ..where((tbl) => tbl.majorTypeId.equals(majorType.id)))
        .get();
    var standardSegments = await (select(ninStandardSegment)
          ..where((tbl) =>
              tbl.majorTypeLECId.isIn(majorTypeLec.map((e) => e.id).toList())))
        .get();
    return await Detailed<NinStandardSegmentData>()
        .fromList(standardSegments, locale);
  }

  Future<NinElementarySegmentData> getElementarySegmentById(String id) =>
      (select(ninElementarySegment)..where((tbl) => tbl.id.equals(id)))
          .getSingle();

  Future<List<NinElementarySegmentData>>
      getElementarySegmentByElementarySegmentGroupId(
          // TODO improve speed here
          String? elementarySegmentGroupId) async {
    var elementarySegmentGroups = await (select(ninElementarySegmentGroup)
          ..where((tbl) => tbl.id.equals(elementarySegmentGroupId)))
        .get();
    var elementarySegmentIds =
        elementarySegmentGroups.map((e) => e.elementarySegmentId);
    return (select(ninElementarySegment)
          ..where((tbl) => tbl.id.isIn(elementarySegmentIds)))
        .get();
  }

  Future<List<NinElementarySegmentGroupData>>
      getElementarySegmentGroupByStandardSegmentAndMajorType(
          String? standardSegmentId, String? majorTypeId) {
    return (select(ninElementarySegmentGroup)
          ..where((tbl) =>
              tbl.standardSegmentId.equals(standardSegmentId) &
              tbl.majorTypeId.equals(majorTypeId)))
        .get();
  }

  Future<List<NinElementarySegmentData>> getElementarySegmentsByIds(
          List<String?> ids) =>
      (select(ninElementarySegment)..where((tbl) => tbl.id.isIn(ids))).get();

  Future<List<String?>> getGadElementarySegmentGroupIdsByStandardSegment(
      NinStandardSegmentData standardSegment,
      List<String> allElementarySegmentGroupIds,
      List<String> elementarySegments) async {
    var res = select(ninElementarySegmentGroup)
      ..where((tbl) => tbl.id.isIn(allElementarySegmentGroupIds))
      ..where((tbl) => tbl.elementarySegmentId.isIn(elementarySegments));
    return (await res.get()).map((e) => e.id).toSet().toList();
  }

  Future<List<Detailed<NinElementarySegmentGroupDetailData>>>
      getElementarySegmentsByElementarySegmentGroupId(
          String elementarySegmentGroupId, Locale locale) async {
    var elementarySegmentGroupDetails =
        await (select(ninElementarySegmentGroupDetail)
              ..where((tbl) => tbl.elementarySegmentGroupId
                  .equals(elementarySegmentGroupId)))
            .get();
    var res = List<Detailed<NinElementarySegmentGroupDetailData>>.empty(
        growable: true);
    for (var esgd in elementarySegmentGroupDetails) {
      var detailed = await Detailed<NinElementarySegmentGroupDetailData>()
          .initialize(esgd, locale);
      res.add(detailed);
    }
    return res;
  }

  Future<List<NinElementarySegmentData>> getElementarySegmentsByLec(
          NinLECData? lec) =>
      (select(ninElementarySegment)..where((tbl) => tbl.lecId.equals(lec!.id)))
          .get();

  Future<List<NinElementarySegmentGroupDetailData>>
      getElementarySegmentsGroupDetailsByLec(NinLECData? lec) =>
          (select(ninElementarySegmentGroupDetail)
                ..where((tbl) => tbl.lecId.equals(lec!.id)))
              .get();

  Future<List<String?>> getElementarySegmentGroupsByElementarySegments(
      List<NinElementarySegmentData> elementarySegments) async {
    var elementaryIds = elementarySegments.map((e) => e.id);
    var elementarySegmentGroups = await (select(ninElementarySegmentGroup)
          ..where((tbl) => tbl.elementarySegmentId.isIn(elementaryIds)))
        .get();
    var elementarySegmentGroupIds =
        elementarySegmentGroups.map((e) => e.id).toSet().toList();
    return elementarySegmentGroupIds;
  }

  Future<List<String?>> getGadElementarySegmentGroupsIdsByMajorTypeLecId(
      NinMajorTypeLECData majorTypeLecId) async {
    var esg = await (select(ninElementarySegmentGroup)
          ..where((tbl) =>
              tbl.majorTypeId.equals(majorTypeLecId.majorTypeId) &
              tbl.lecId.equals(majorTypeLecId.lecId)))
        .get();
    return esg.map((e) => e.id).toSet().toList();
  }

  Future<Detailed<NinLECData>> getLecById(String? lecId, Locale? locale) async {
    var lec = await (select(ninLEC)..where((tbl) => tbl.id.equals(lecId)))
        .getSingle();
    var res = Detailed<NinLECData>();
    await res.initialize(lec, locale);
    return res;
  }

  Future<List<Detailed<NinMinorTypeData>>> getMinorTypesByIds(
      List<String> minorTypeIds, Locale locale) async {
    var minorTypes = await (select(ninMinorType)
          ..where((tbl) => tbl.id.isIn(minorTypeIds)))
        .get();
    return await Detailed<NinMinorTypeData>().fromList(minorTypes, locale);
  }

  Future<List<NinMinorTypeScaledData>> getMinorTypeScaledById(
          String minorTypeScaledId) =>
      (select(ninMinorTypeScaled)
            ..where((tbl) => tbl.id.equals(minorTypeScaledId)))
          .get();

  Future<List<NinSpecie>> getSpeciesByFilter(String filter) =>
      (select(ninSpecies)
            ..where((tbl) =>
                tbl.scientificName.like('%$filter%') |
                tbl.vernacularName.like('%$filter%')))
          .get();

  Future<List<NinGadValueData>> getGadValuesBySpeciesId(
          int? speciesId, String? majorTypeId) =>
      (select(ninGadValue)
            ..where((tbl) =>
                tbl.speciesId.equals(speciesId) &
                tbl.majorTypeId.equals(majorTypeId)))
          .get();

  Future<List<NinElementarySegmentCombinationData>>
      getElementarySegmentCombinationsByElementarySegmentCombinationId(
              String? elementarySegmentCombinationId) =>
          (select(ninElementarySegmentCombination)
                ..where((tbl) => tbl.id.equals(elementarySegmentCombinationId)))
              .get();

  Future<List<NinGadModifierData>> getGadModifiersBySpeciesId(
          int? speciesId, String? majorTypeId) =>
      (select(ninGadModifier)
            ..where((tbl) =>
                tbl.speciesId.equals(speciesId) &
                tbl.majorTypeId.equals(majorTypeId)))
          .get();

  Future<List<NinLECData>> getAllLec() => select(ninLEC).get();

  Future<List<Detailed<NinMajorTypeData>>> getMajorTypesByLec(
      String? lecId, Locale locale) async {
    var mtLecs = await (select(ninMajorTypeLEC)
          ..where((tbl) => tbl.lecId.equals(lecId)))
        .get();
    var mtIds = mtLecs.map((e) => e.majorTypeId);
    var mts = await (select(ninMajorType)
          ..where((tbl) => tbl.id.isIn(mtIds))
          ..orderBy([
            (t) => OrderingTerm(expression: t.majorTypeGroupId),
            (t) => OrderingTerm(expression: t.order)
          ]))
        .get();
    return Detailed<NinMajorTypeData>().fromList(mts, locale);
  }

  Future<List<Detailed<NinMajorTypeData>>> getMajorTypesForSpecie(
      NinSpecie specie, Locale locale) async {
    // TODO implement when more GAD datasets are available
    // var q = select(ninGadValue)
    //   ..where((tbl) => tbl.speciesId.equals(specie.scientificNameId));
    // var mtIds = (await q.map((e) => e.majorTypeId).get()).toSet();
    // mtIds
    var q = select(ninMajorType)..where((tbl) => tbl.id.equals('T-4'));
    var mts = await q.get();
    var res = await Detailed<NinMajorTypeData>().fromList(mts, locale);
    return res;
  }

  Future<List<Detailed<NinMinorTypeScaledData>>>
      getDetailedMinorTypesScaledById(
          String? minorTypeScaledId, Locale locale) async {
    var minorTypesScaled = await (select(ninMinorTypeScaled)
          ..where((tbl) => tbl.id.equals(minorTypeScaledId))
          ..map((e) => e.detailId))
        .get();
    var res = await Detailed<NinMinorTypeScaledData>()
        .fromList(minorTypesScaled, locale);
    res.removeWhere((element) => element.name == null);
    return res;
  }

  @override
  int get schemaVersion => 86;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (Migrator m) {
        return m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        // for (final table in allTables) {
        //   await m.deleteTable(table.actualTableName);
        // }
        m.createAll();
      });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return getLazyDb();
  });
}

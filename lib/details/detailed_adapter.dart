import 'dart:ui';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:naturinorge_guide/main.dart';

class Detailed<K> {
  K? data;
  String? name;

  Locale? locale;
  String? detailId;
  String? nameHeader;
  String? description;
  String? descriptionHeader;
  Map<String, String?>? other;

  Future initialize(dynamic data, Locale? locale) async {
    this.data = data;
    this.locale = locale;
    this.detailId = data.detailId;

    await _getRelations();
    return this;
  }

  Future<List<Detailed<K>>> fromList(
      List<dynamic> dataList, Locale? locale) async {
    var res = List<Detailed<K>>.empty(growable: true);
    for (var e in dataList) {
      var detailed = await Detailed<K>().initialize(e, locale);
      res.add(detailed);
    }

    return res;
  }

  Future _getRelations() async {
    var details = await db!.getDetails(detailId, locale);
    if (details == null || details.length == 0) {
      return;
    }

    var nameDetail =
        details.firstWhereOrNull((element) => element.key == '__name__');
    if (nameDetail != null) {
      name = fixTextFromOutside(nameDetail.value);
      nameHeader = tr('__name__');
    }

    var descriptionDetail =
        details.firstWhereOrNull((element) => element.key == '__description__');
    if (descriptionDetail == null) {
    } else {
      description = fixTextFromOutside(descriptionDetail.value);
    }
    descriptionHeader = tr('__description__');

    details.removeWhere((element) =>
        element.key == '__name__' || element.key == '__description__');
    other = Map.fromIterable(details,
        key: (e) {
          var header = e.key;
          try {
            header = tr(header);
          } catch (e) {}
          return header;
        },
        value: (e) => fixTextFromOutside(e.value));
  }
}

String? fixTextFromOutside(String? input) {
  if (input == null) {
    return input;
  }
  var res = input.replaceAll('\\t', '    ');
  res = res.replaceAll('\\n', '\n\n');
  return res;
}

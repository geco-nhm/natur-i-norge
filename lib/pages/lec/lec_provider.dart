import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/db_adapters.dart';
import 'package:naturinorge_guide/main.dart';

class LecProvider extends ChangeNotifier {
  var _lecAdapters = List<LecAdapter>.empty(growable: true);
  final Locale locale;

  LecProvider(this.locale);

  Future initalize() async {
    if (_lecAdapters.length > 0) {
      return;
    }
    var allLec = await db!.getAllLec();
    var lecAdapters = allLec.map((e) => LecAdapter(locale, e));
    for (var lec in lecAdapters) {
      await lec.getRelations();
      _lecAdapters.add(lec);
    }
    notifyListeners();
  }

  List<LecAdapter> get lecAdapters => _lecAdapters;
}

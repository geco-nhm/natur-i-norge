import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_selector_page.dart';

enum ButtonState { AVAILABLE, SELECTED, UNAVAILABLE }

class NinStructureProvider extends ChangeNotifier {
  var _ninMajorTypeGroups = List<Detailed<NinMajorTypeGroupData>>.empty();
  var _ninMajorTypes = List<Detailed<NinMajorTypeData>>.empty();

  Detailed<NinMajorTypeGroupData>? _selectedMajorTypeGroupData;
  Detailed<NinMajorTypeData>? _selectedMajorTypeData;
  Locale? _locale;
  bool _isLoading = true;
// Scrolling

// MajorTypeGroup

  NinStructureProvider(Locale locale) {
    _locale = locale;
  }

  Future setLocale(Locale locale) async {
    _locale = locale;
    await initialize();
  }

  Future initialize() async {
    await _loadMajorTypeGroups();
    _isLoading = false;
    notifyListeners();
  }

  Future setSelectedMajorTypeGroup(
      BuildContext context, Detailed<NinMajorTypeGroupData>? data) async {
    if (_selectedMajorTypeGroupData != data) {
      _selectedMajorTypeGroupData = data;
      _selectedMajorTypeData = null;
      _ninMajorTypes = await db!.filteredMajorTypes(data!.data!.id, _locale);
      notifyListeners();
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => MajorTypeSelectorPage()));
  }

  Detailed<NinMajorTypeGroupData>? get selectedMajorTypeGroup =>
      _selectedMajorTypeGroupData;

  List<Detailed<NinMajorTypeGroupData>> get majorTypeGroups =>
      _ninMajorTypeGroups;

  Future _loadMajorTypeGroups() async {
    List<NinMajorTypeGroupData>? majorTypeGroups;
    while (majorTypeGroups == null || majorTypeGroups.length == 0) {
      try {
        majorTypeGroups = await db!.allMajorTypeGroups;
      } catch (e) {}
    }
    _ninMajorTypeGroups = await Detailed<NinMajorTypeGroupData>()
        .fromList(majorTypeGroups, locale);
  }

  // MajorType
  List<Detailed<NinMajorTypeData>> get majorTypes => _ninMajorTypes;

  bool shouldLoadMajorType(Detailed<NinMajorTypeData>? data) {
    if (_selectedMajorTypeData != data) {
      _selectedMajorTypeData = data;
      return true;
    } else {
      return false;
    }
  }

  set setLoading(bool setLoading) {
    _isLoading = setLoading;
    notifyListeners();
  }

  Locale? get locale => _locale;
  bool get isLoading => _isLoading;
  Detailed<NinMajorTypeData>? get selectedMajorType => _selectedMajorTypeData;
}

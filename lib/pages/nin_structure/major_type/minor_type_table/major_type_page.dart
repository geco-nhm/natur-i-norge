import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/major_type_page_landscape.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/major_type_page_portrait.dart';

class MajorTypePage extends StatelessWidget {
  const MajorTypePage({Key? key, this.majorType}) : super(key: key);
  final Detailed<NinMajorTypeData>? majorType;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      if (constrains.maxWidth < 1000) {
        return MajorTypePagePortrait(majorType: majorType);
      } else {
        return MajorTypePageLandscape(majorType: majorType);
      }
    });
  }
}

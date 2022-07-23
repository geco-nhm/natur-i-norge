import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_button.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:naturinorge_guide/tools/global_vars.dart';
import 'package:provider/provider.dart';

class MajorTypeSelector extends StatelessWidget {
  const MajorTypeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      primary: false,
      shrinkWrap: true,
      maxCrossAxisExtent: GRIDVIEW_CROSS_AXIS_EXTENT,
      childAspectRatio: GRIDVIEW_ASPECT_RATIO,
      clipBehavior: Clip.none,
      // crossAxisSpacing: 12,
      // mainAxisSpacing: 12,
      children: Provider.of<NinStructureProvider>(context)
          .majorTypes
          .map((e) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: MajorTypeButton(
                  ninMajorType: e,
                ),
              ))
          .toList(),
    );
  }
}

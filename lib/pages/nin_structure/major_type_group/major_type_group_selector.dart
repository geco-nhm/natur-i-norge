import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type_group/major_type_group_button.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:provider/provider.dart';

class MajorTypeGroupSelector extends StatelessWidget {
  const MajorTypeGroupSelector({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      // primary: false,
      shrinkWrap: true,
      maxCrossAxisExtent: 170,
      childAspectRatio: 1,
      clipBehavior: Clip.none,
      // crossAxisSpacing: 12,
      // mainAxisSpacing: 12,
      children: Provider.of<NinStructureProvider>(context, listen: false)
          .majorTypeGroups
          .map((e) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: MajorTypeGroupButton(
                  ninMajorTypeGroup: e,
                ),
              ))
          .toList(),
    );
  }
}

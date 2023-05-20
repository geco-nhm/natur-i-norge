import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/db_adapters.dart';
import 'package:naturinorge_guide/pages/lec/lec_detail_page.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/axis_block.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/standard_segments_reset.dart';
import 'package:naturinorge_guide/tools/get_lec_color.dart';
import 'package:naturinorge_guide/tools/global_vars.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

class SecondaryAxisOptions extends StatelessWidget {
  const SecondaryAxisOptions({Key? key}) : super(key: key);

  String _buildsegmentString(StandardSegmentAdapter ssa) {
    var order = ssa.standardSegment.data!.order!;
    var es = ssa.elementarySegments!.map((e) => e.value).join('|');
    return '$order\n$es';
  }

  @override
  Widget build(BuildContext context) {
    // List<Widget> body = List<Widget>.empty(growable: true);
    if (Provider.of<MajorTypeProvider>(context).zAxis == null) {
      return Container();
    }

    var body = Provider.of<MajorTypeProvider>(context).zAxis!.map((axis) {
      var standarSegments = axis.standardSegments
          .map((e) => (_buildsegmentString(e)).toString())
          .toList();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SecondaryAxisWidget(
          standarSegments: standarSegments,
          axis: axis,
        ),
      );
    }).toList();
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LKM',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            StandardSegmentsResetWidget(),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: body,
        ),
      ],
    );
  }
}

class SecondaryAxisWidget extends StatelessWidget {
  final AxisBlock? axis;
  const SecondaryAxisWidget({
    Key? key,
    required this.standarSegments,
    this.axis,
  }) : super(key: key);

  final List<String> standarSegments;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: getLecColor(axis!.lecAdapter.majorTypeLec),
      elevation: MATERIAL_ELEVATION,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          isThreeLine: true,
          trailing: IconButton(
              icon: Icon(Icons.info),
              onPressed: () async {
                var lec = LecAdapter(context.locale, axis!.lecAdapter.lec.data);
                await lec.getRelations();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LecDetailPage(
                              lec: lec,
                            )));
              }),
          title: Text(
            '${axis!.lecAdapter.lec.data!.id} - ${axis!.lecAdapter.lec.name ?? ""}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ToggleSwitch(
                totalSwitches: standarSegments.length,
                minWidth: 60.0,
                labels: standarSegments,
                onToggle: (value) =>
                    Provider.of<MajorTypeProvider>(context, listen: false)
                        .setSecondaryStandardSegment(
                            axis!.standardSegments[value!]),
                initialLabelIndex: axis!.standardSegments.indexWhere((e) =>
                    e.standardSegment.data!.id ==
                    Provider.of<MajorTypeProvider>(context)
                        .selectedSecondaryAxisSegments!
                        .firstWhere((element) =>
                            element.standardSegment.data!.lecId ==
                            axis!.lecAdapter.lec.data!.id)
                        .standardSegment
                        .data!
                        .id),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

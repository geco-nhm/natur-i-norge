import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/db_adapters.dart';
import 'package:naturinorge_guide/pages/lec/lec_detail_page.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/axis_block.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/axis_label_name.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/elementary_segment_widget.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/standard_segment_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class AxisLabel extends StatelessWidget {
  final AxisBlock? axisBlock;
  final Axis orientation;
  const AxisLabel(
      {Key? key, required this.axisBlock, required this.orientation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var standardSegmentWidgets = List<Widget>.empty(growable: true);
    for (var ss in axisBlock!.standardSegments) {
      // print('${ss.standardSegment.data.id} ${ss.elementarySegments.length}');
      standardSegmentWidgets.add(Expanded(
        flex: ss.elementarySegmentGroups.length,
        child: StandardSegmentWidget(
          standardSegmentAdapter: ss,
        ),
      ));
    }

    List<Widget> bodyParts = [
      Expanded(
        flex: 1,
        child: AxisLabelNameWidget(axisBlock: axisBlock),
      ),
      Expanded(
        flex: 1,
        child: Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: standardSegmentWidgets,
        ),
      ),
      Expanded(
        flex: 1,
        child: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: axisBlock!.standardSegments
                .expand((element) => element.elementarySegmentGroups)
                .map((e) => ElementarySegmentLabelWidget(
                      elementarySegmentGroupId: e,
                    ))
                .toList()),
      )
    ];

    if (orientation == Axis.horizontal) {
      bodyParts = bodyParts.reversed.toList();
    }

    var body = GestureDetector(
        onTap: () async {
          var lec = LecAdapter(context.locale, axisBlock!.lecAdapter.lec.data);
          await lec.getRelations();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => LecDetailPage(
                        lec: lec,
                      )));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: bodyParts,
        ));

    if (orientation == Axis.vertical)
      return RotatedBox(
        quarterTurns: 3,
        child: body,
      );
    else
      return body;
  }
}

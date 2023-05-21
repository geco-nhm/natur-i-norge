import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/axis_label.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/table_body.dart';
import 'package:provider/provider.dart';

class MinorTypeTable extends StatelessWidget {
  const MinorTypeTable({Key? key}) : super(key: key);
  static int spacing = 2;
  static int sidePadding = spacing;
  static double labelWidth = 70.0;

  Size getSize(BuildContext context, BoxConstraints boxConstrains) {
    if (!boxConstrains.hasBoundedWidth) {
      throw Exception("No width constrain for Table Widget");
    }
    var ratio;
    if (Provider.of<MajorTypeProvider>(context).yAxis != null) {
      ratio = Provider.of<MajorTypeProvider>(context)
              .xAxis!
              .standardSegments
              .expand((element) => element.elementarySegmentGroups)
              .length /
          Provider.of<MajorTypeProvider>(context)
              .yAxis!
              .standardSegments
              .expand((element) => element.elementarySegmentGroups)
              .length;
    } else {
      ratio = Provider.of<MajorTypeProvider>(context)
          .xAxis!
          .standardSegments
          .expand((element) => element.elementarySegmentGroups)
          .length
          .toDouble();
    }
    var maxWidth = boxConstrains.maxWidth;
    var maxHeight = MediaQuery.of(context).size.height - kToolbarHeight;

    double xSize;
    double ySize;
    var envelopeRatio = maxWidth / maxHeight;
    if (envelopeRatio < ratio) {
      xSize = boxConstrains.maxWidth - sidePadding - labelWidth;
      ySize = xSize / ratio;
    } else {
      ySize = maxHeight - sidePadding - labelWidth - 40;
      xSize = ySize * ratio;
    }
    return Size(xSize, ySize);
  }

  @override
  Widget build(BuildContext context) {
    if (Provider.of<MajorTypeProvider>(context).isLoading) {
      return LinearProgressIndicator();
    }

    return LayoutBuilder(builder: (context, boxContrains) {
      var size = getSize(context, boxContrains);
      var xSize = size.width;
      var ySize = size.height;
      return Wrap(
        direction: Axis.vertical,
        children: [
          Row(
            children: [
              if (Provider.of<MajorTypeProvider>(context).yAxis != null)
                Container(
                  clipBehavior: Clip.none,
                  height: ySize,
                  width: labelWidth,
                  child: Material(
                    child: AxisLabel(
                      axisBlock: Provider.of<MajorTypeProvider>(context).yAxis,
                      orientation: Axis.vertical,
                    ),
                  ),
                ),
              Container(
                height: ySize,
                width: xSize,
                child: TableBody(
                  xSize: xSize,
                  ySize: ySize,
                ),
              )
            ],
          ),
          Row(
            children: [
              if (Provider.of<MajorTypeProvider>(context).yAxis != null)
                Container(
                  height: labelWidth,
                  width: labelWidth,
                  // child: SecondaryAxisSwitch(),
                ),
              Container(
                padding: EdgeInsets.all(spacing.toDouble()),
                height: labelWidth,
                width: xSize,
                child: Material(
                  child: AxisLabel(
                    axisBlock: Provider.of<MajorTypeProvider>(context).xAxis,
                    orientation: Axis.horizontal,
                  ),
                ),
              ),
            ],
          )
        ],
      );
    });
  }
}

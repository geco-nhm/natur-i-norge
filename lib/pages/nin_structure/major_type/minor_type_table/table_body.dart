import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/gad_overlay.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/scaled_minor_type.dart';
import 'package:provider/provider.dart';

class TableBody extends StatelessWidget {
  const TableBody({Key? key, this.xSize, this.ySize}) : super(key: key);
  final double? xSize;
  final double? ySize;

  @override
  Widget build(BuildContext context) {
    if (Provider.of<MajorTypeProvider>(context).minorTypes == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    var minorTypesBlocks = Provider.of<MajorTypeProvider>(context)
        .minorTypeScaledBlocks!
        .map((e) => ScaledMinorTypeWidget(
              // key: ValueKey(uuid.v4()),
              minorTypeBlock: e,
            ))
        .toList();
    var staggeredTiles = Provider.of<MajorTypeProvider>(context)
        .minorTypeScaledBlocks!
        .map((e) => StaggeredTile.count(e!.width, e.height.toDouble()))
        .toList();
    return Stack(
      children: [
        Container(
          width: xSize,
          height: ySize,
          child: StaggeredGridView.count(
            key: ValueKey(uuid.v4()),
            addAutomaticKeepAlives: true,
            padding: EdgeInsets.all(4.0),
            crossAxisSpacing: 2.0,
            mainAxisSpacing: 2.0,
            physics: new NeverScrollableScrollPhysics(),
            crossAxisCount: Provider.of<MajorTypeProvider>(context)
                .xAxis!
                .standardSegments
                .expand((element) => element.elementarySegmentGroups)
                .length,
            reverse: true,
            primary: true,
            // shrinkWrap: true,
            children: minorTypesBlocks,
            staggeredTiles: staggeredTiles,
          ),
        ),
        if (Provider.of<MajorTypeProvider>(context).gadArray != null &&
            Provider.of<MajorTypeProvider>(context).showGad == 0)
          IgnorePointer(
            child: GadOverlay(),
          ),
      ],
    );
  }
}

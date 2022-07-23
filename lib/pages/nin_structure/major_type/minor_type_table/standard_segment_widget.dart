import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/db_adapters.dart';
import 'package:naturinorge_guide/tools/global_vars.dart';

class StandardSegmentWidget extends StatelessWidget {
  final StandardSegmentAdapter? standardSegmentAdapter;
  const StandardSegmentWidget({Key? key, this.standardSegmentAdapter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var name = standardSegmentAdapter!.standardSegment.name ??
        (standardSegmentAdapter!.standardSegment.data!.order! + 1).toString();

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Material(
        elevation: MATERIAL_ELEVATION,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Center(
            child: AutoSizeText(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

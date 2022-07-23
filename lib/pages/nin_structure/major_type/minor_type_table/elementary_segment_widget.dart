import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/tools/global_vars.dart';

class ElementarySegmentLabelWidget extends StatelessWidget {
  final String? elementarySegmentGroupId;
  const ElementarySegmentLabelWidget({Key? key, this.elementarySegmentGroupId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Material(
          elevation: MATERIAL_ELEVATION,
          // padding: EdgeInsets.all(2),
          child: Center(
            child: AutoSizeText(elementarySegmentGroupId!.split('.')[1]),
          ),
        ),
      ),
    );
  }
}

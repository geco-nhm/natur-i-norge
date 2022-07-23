import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:provider/provider.dart';

class StandardSegmentsResetWidget extends StatelessWidget {
  const StandardSegmentsResetWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Provider.of<MajorTypeProvider>(context).allowReset) {
      return Tooltip(
        message: 'Reset',
        child: IconButton(
            icon: Icon(Icons.restore),
            onPressed: () =>
                Provider.of<MajorTypeProvider>(context, listen: false)
                    .resetSelectedAxisSegments()),
      );
    } else {
      return Container();
    }
  }
}

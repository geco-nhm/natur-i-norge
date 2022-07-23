import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:provider/provider.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isLoading = Provider.of<NinStructureProvider>(context).isLoading ||
        Provider.of<MajorTypeProvider>(context).isLoading;
    if (isLoading) {
      var size = MediaQuery.of(context).size;
      return AbsorbPointer(
        child: Container(
          height: size.height - kToolbarHeight,
          width: size.width,
          color: Colors.black.withOpacity(0.8),
        ),
      );
    } else {
      return Container();
    }
  }
}

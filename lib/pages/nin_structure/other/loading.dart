import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:provider/provider.dart';

class LoadingWidget extends StatelessWidget with PreferredSizeWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isLoading = Provider.of<NinStructureProvider>(context).isLoading ||
        Provider.of<MajorTypeProvider>(context).isLoading;
    if (!isLoading) {
      return Container();
    } else {
      return LinearProgressIndicator();
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(4.0);
}

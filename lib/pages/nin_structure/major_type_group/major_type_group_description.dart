import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:provider/provider.dart';

class MajorTypeGroupDetails extends StatelessWidget {
  const MajorTypeGroupDetails({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Provider.of<NinStructureProvider>(context).selectedMajorTypeGroup ==
            null ||
        Provider.of<NinStructureProvider>(context)
                .selectedMajorTypeGroup
                ?.description ==
            null) {
      return Container();
    }
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              Provider.of<NinStructureProvider>(context)
                  .selectedMajorTypeGroup!
                  .name!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Divider(),
            Text(Provider.of<NinStructureProvider>(context)
                .selectedMajorTypeGroup!
                .description!),
          ],
        ),
      ),
    );
  }
}

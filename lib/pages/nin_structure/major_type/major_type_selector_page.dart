import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_selector.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type_group/major_type_group_description.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/other/loading.dart';
import 'package:provider/provider.dart';

class MajorTypeSelectorPage extends StatelessWidget {
  const MajorTypeSelectorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mtg = Provider.of<NinStructureProvider>(context).selectedMajorTypeGroup!;
    return Scaffold(
        appBar: AppBar(
          title: AutoSizeText('${mtg.data!.id} - ${mtg.name}'),
          bottom: LoadingWidget(),
          actions: [
            IconButton(
                icon: Icon(Icons.home),
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => !route.navigator!.canPop()))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListView(
            children: [
              MajorTypeGroupDetails(),
              Divider(),
              MajorTypeSelector(),
            ],
          ),
        ));
  }
}

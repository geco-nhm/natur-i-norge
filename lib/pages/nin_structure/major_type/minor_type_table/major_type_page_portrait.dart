import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/gad_overlay/add_species_btn.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/gad_overlay/selected_species_list.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/secondary_axis_dialog.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/table_options.dart';
import 'package:naturinorge_guide/pages/nin_structure/other/loading.dart';
import 'package:provider/provider.dart';

class MajorTypePagePortrait extends StatelessWidget {
  final Detailed<NinMajorTypeData>? majorType;
  const MajorTypePagePortrait({Key? key, required this.majorType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Provider.of<MajorTypeProvider>(context).isLoading) {
      return Container();
    }
    List<Widget> body = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: AutoSizeText(
          majorType!.name!,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
      if (majorType!.description != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AutoSizeText(
            majorType!.description!,
            wrapWords: true,
            softWrap: true,
          ),
        ),
    ];
    if (Provider.of<MajorTypeProvider>(context).xAxis != null) {
      body.addAll([
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TableOptions(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SecondaryAxisOptions(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Center(child: MinorTypeTable()),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: AddSpecieButtons(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SelectedSpeciesList(),
        ),
      ]);
    }
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: AutoSizeText(
              '${majorType!.data!.id} ${majorType!.name}',
              // style: Theme.of(context).textTheme.headline3,
            ),
            bottom: LoadingWidget(),
            actions: [
              IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => !route.navigator!.canPop()))
            ],
          ),
          SliverList(delegate: SliverChildListDelegate.fixed(body))
        ],
      ),
    );
  }
}

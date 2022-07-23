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
import 'package:naturinorge_guide/tools/global_vars.dart';
import 'package:provider/provider.dart';

const double sidebarWidth = 450.0;

class MajorTypePageLandscape extends StatelessWidget {
  final Detailed<NinMajorTypeData>? majorType;

  const MajorTypePageLandscape({Key? key, required this.majorType})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body;
    if (Provider.of<MajorTypeProvider>(context).isLoading) {
      body = Container();
    }
    if (Provider.of<MajorTypeProvider>(context).xAxis == null) {
      body = Container(
        child: Column(
          children: [
            Text(
              majorType!.description!,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ],
        ),
      );
    } else {
      body = Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
                width: sidebarWidth,
                child: Scrollbar(
                  child: ListView(
                    clipBehavior: Clip.none,
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: AutoSizeText(
                      //     ninMajorType.name,
                      //     wrapWords: false,
                      //     style: Theme.of(context).textTheme.headline2,
                      //     textAlign: TextAlign.center,
                      //   ),
                      // ),
                      // Divider(),
                      Material(
                        elevation: MATERIAL_ELEVATION,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            majorType!.description!,
                            // trimLines: 10,
                            // trimMode: TrimMode.Line,
                            // trimExpandedText: LocaleKeys.read_mode.tr(),
                            // trimCollapsedText: LocaleKeys.show_less.tr(),
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                      ),
                      Divider(),

                      TableOptions(),
                      Divider(),

                      SecondaryAxisOptions(),
                      Divider(),
                      SelectedSpeciesList(),
                      AddSpecieButtons(),
                    ],
                  ),
                )),
            VerticalDivider(),
            Container(
              // color: Colors.red,
              width: MediaQuery.of(context).size.width - sidebarWidth - 50,
              child: Center(child: MinorTypeTable()),
            )
          ],
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
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
        body: body);
  }
}

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/minor_type_block.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/minor_type_description.dart';
import 'package:naturinorge_guide/tools/global_vars.dart';

class ScaledMinorTypeWidget extends StatelessWidget {
  final MinorTypeBlock? minorTypeBlock;
  const ScaledMinorTypeWidget({Key? key, this.minorTypeBlock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (minorTypeBlock!.minorTypeScaled == null) {
      return Container();
    } else
      return GestureDetector(
        onTap: () => showDialog(
            context: context,
            builder: (context) => MinorTypeDescription(
                  minorTypeBlock: minorTypeBlock,
                )),
        child: Material(
          color: Colors.lightGreen[50],
          elevation: MATERIAL_ELEVATION,
          child: LayoutBuilder(builder: (context, constrains) {
            // print(
            //     'width:${constrains.maxWidth} height:${constrains.maxHeight}');
            if (constrains.maxHeight < 20 || constrains.maxWidth < 40) {
              return Center(
                child: AutoSizeText(
                  minorTypeBlock!.minorTypeScaled!.minorTypeScaledId.split('-')
                      .last,
                  maxLines: 1,
                ),
              );
            } else if (constrains.maxHeight < 62 || constrains.maxWidth < 50) {
              return Center(
                child: AutoSizeText(
                  minorTypeBlock!.minorTypeScaled!.minorTypeScaledId.split('-')
                      .sublist(1)
                      .join('-'),
                  maxLines: 1,
                ),
              );
            } else {
              var name = minorTypeBlock!.minorTypeScaled!.name;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      // height: 20,
                      child: Center(
                        child: AutoSizeText(
                          minorTypeBlock!.minorTypeScaled!.minorTypeScaledId,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    Center(
                      child: AutoSizeText(
                        name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        wrapWords: false,
                      ),
                    )
                  ],
                ),
              );
            }
          }),
        ),
      );
  }
}

import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/gad_cell.dart';
import 'package:provider/provider.dart';

class GadOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var gadArray = Provider.of<MajorTypeProvider>(context).gadArray!;
    return Container(
        color: Colors.white70,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: gadArray
              .map((column) => Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: column
                          .map<Widget>((cell) => GadCell(
                                number: cell,
                              ))
                          .toList()
                          .reversed
                          .toList(),
                    ),
                  ))
              .toList(),
        ));
  }
}

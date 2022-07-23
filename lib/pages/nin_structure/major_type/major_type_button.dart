import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/major_type_page.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:provider/provider.dart';

class MajorTypeButton extends StatefulWidget {
  const MajorTypeButton({Key? key, this.ninMajorType}) : super(key: key);
  final Detailed<NinMajorTypeData>? ninMajorType;

  @override
  _MajorTypeButtonState createState() => _MajorTypeButtonState();
}

class _MajorTypeButtonState extends State<MajorTypeButton> {
  // var _shape = NeumorphicShape.convex;
  // Color _bgColor;
  // _initialize(BuildContext context) {
  //   var selected = Provider.of<NinStructureProvider>(context).selectedMajorType;

  //   if (selected != null && selected.data.id == widget.ninMajorType.data.id) {
  //     _shape = NeumorphicShape.concave;
  //     _bgColor = NeumorphicTheme.of(context).current.accentColor;
  //   } else {
  //     _shape = NeumorphicShape.convex;
  //     _bgColor = NeumorphicTheme.of(context).current.baseColor;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // _initialize(context);
    return Container(
      child: ElevatedButton(
          // style: NeumorphicStyle(
          //   shape: _shape,
          //   color: _bgColor,
          // ),
          child: Row(
            children: [
              Text(widget.ninMajorType!.data!.id!),
              VerticalDivider(),
              Flexible(
                  child: AutoSizeText(
                widget.ninMajorType!.name!,
                maxLines: 4,
                wrapWords: true,
                softWrap: true,
                minFontSize: 8,
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
          onPressed: () async {
            Provider.of<NinStructureProvider>(context, listen: false)
                .setLoading = true;
            if (Provider.of<NinStructureProvider>(context, listen: false)
                .shouldLoadMajorType(widget.ninMajorType))
              await Provider.of<MajorTypeProvider>(context, listen: false)
                  .load(widget.ninMajorType);
            Provider.of<NinStructureProvider>(context, listen: false)
                .setLoading = false;
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => MajorTypePage(
                      majorType: widget.ninMajorType,
                    )));
          }),
    );
  }
}

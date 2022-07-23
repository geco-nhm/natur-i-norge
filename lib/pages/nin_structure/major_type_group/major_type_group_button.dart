import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/details/detailed_adapter.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:provider/provider.dart';

class MajorTypeGroupButton extends StatefulWidget {
  MajorTypeGroupButton({Key? key, this.ninMajorTypeGroup}) : super(key: key);

  final Detailed<NinMajorTypeGroupData>? ninMajorTypeGroup;

  @override
  _MajorTypeGroupButtonState createState() => _MajorTypeGroupButtonState();
}

class _MajorTypeGroupButtonState extends State<MajorTypeGroupButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 3,
            child: Center(
                child: Text(
              widget.ninMajorTypeGroup!.data!.id!,
              textScaleFactor: 2,
            )),
          ),
          Expanded(
              flex: 2,
              child: AutoSizeText(
                // 'Maaaaaaaaaa\u00ADrgaret­Are­You­Grieving­Over­Goldengrove­Unleaving­Leaves­Like­The­Things­Of­Man­You­With­Your­Fresh­Thoughts­Care­For­Can­You­Ah­As­The­Heart­Grows­Older­It­Will­Come­To­Such­Sights­Colder­By­And­By­Nor­Spare­A­Sigh­Though­Worlds­Of­Wanwood­Leafmeal­Lie­And­Yet­You­Will­Weep­And­Know­Why­Now­No­Matter­Child­The­Name­Sorrows­Springs­Are­The­Same­Nor­Mouth­Had­No­Nor­Mind­Expressed­What­Heart­Heard­Of­Ghost­Guessed­It­Is­The­Blight­Man­Was­Born­For­It­Is­Margaret­You­Mourn­For',
                widget.ninMajorTypeGroup!.name!,
                maxLines: 3,
                wrapWords: true,
                minFontSize: 10,
                textAlign: TextAlign.center,
              ))
        ],
      ),
      onPressed: () {
        Provider.of<NinStructureProvider>(context, listen: false)
            .setSelectedMajorTypeGroup(context, widget.ninMajorTypeGroup);
      },
    );
  }
}

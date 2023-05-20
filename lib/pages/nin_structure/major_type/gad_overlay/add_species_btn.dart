import 'package:flutter/material.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/gad_overlay/species_selector.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';

class AddSpecieButtons extends StatelessWidget {
  const AddSpecieButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Provider.of<MajorTypeProvider>(context).majorType!.data!.id != 'T-4') {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('Legge til arter'), // TODO translation
          onPressed: () => showDialog(
              context: context, builder: (context) => SpeciesSelector()),
        ),
        if (Provider.of<MajorTypeProvider>(context).selectedSpecies.length > 0)
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 26,
                ),
                ToggleSwitch(
                  totalSwitches: 2,
                  labels: ['', ''],
                  icons: [
                    Icons.visibility,
                    Icons.visibility_off,
                  ],
                  onToggle: (idx) =>
                      Provider.of<MajorTypeProvider>(context, listen: false)
                          .setShowGad(idx!),
                  initialLabelIndex:
                      Provider.of<MajorTypeProvider>(context).showGad,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

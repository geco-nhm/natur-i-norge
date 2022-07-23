import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:provider/provider.dart';

class SpeciesSelector extends StatefulWidget {
  const SpeciesSelector({Key? key}) : super(key: key);

  @override
  _SpeciesSelectorState createState() => _SpeciesSelectorState();
}

class _SpeciesSelectorState extends State<SpeciesSelector> {
  List<NinSpecie> species = List<NinSpecie>.empty(growable: true);

  @override
  void initState() {
    db!.getSpeciesByFilter('').then((value) => setState(() {
          species = value;
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Container(
                // height: 60,
                child: TextFormField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search),
                      hintText: 'Søk',
                    ),
                    // initialValue: ,
                    autocorrect: false,
                    onChanged: (filter) async {
                      var newSpecies = await db!.getSpeciesByFilter(filter);
                      setState(() {
                        species = newSpecies;
                      });
                    }),
              ),
            ),
            if (species.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(
                          leading: Text(species[index].scientificName!),
                          subtitle: Text(species[index].vernacularName!),
                          onTap: () {
                            Provider.of<MajorTypeProvider>(context,
                                    listen: false)
                                .addSpecies(species[index]);
                            Navigator.pop(context);
                          },
                        ),
                    childCount: species.length),
              )
          ],
        ),
      ),
    );
  }
}

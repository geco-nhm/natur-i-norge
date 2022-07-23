import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/main.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/minor_type_table/major_type_page.dart';
import 'package:provider/provider.dart';

class SpeciesPage extends StatefulWidget {
  const SpeciesPage({Key? key}) : super(key: key);

  @override
  _SpeciesPageState createState() => _SpeciesPageState();
}

class _SpeciesPageState extends State<SpeciesPage> {
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
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: TextFormField(
              decoration: InputDecoration(
                icon: Icon(Icons.search),
                hintText: 'Søk i Fastmarksskogsmark (T-4)',
              ),
              // initialValue: ,
              autocorrect: true,
              onChanged: (filter) async {
                var newSpecies = await db!.getSpeciesByFilter(filter);
                setState(() {
                  species = newSpecies;
                });
              }),
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.home),
              onPressed: () => Navigator.of(context)
                  .popUntil((route) => !route.navigator!.canPop()))
        ],
      ),
      body: ListView.builder(
          itemCount: species.length,
          itemBuilder: (context, index) => ListTile(
                leading: Text(species[index].scientificName!),
                subtitle: Text(species[index].vernacularName!),
                onTap: () async {
                  var specie = species[index];
                  var mts =
                      await db!.getMajorTypesForSpecie(specie, context.locale);
                  await Provider.of<MajorTypeProvider>(context, listen: false)
                      .load(mts[0]);
                  await Provider.of<MajorTypeProvider>(context, listen: false)
                      .addSpecies(species[index]);
                  Provider.of<MajorTypeProvider>(context, listen: false)
                      .setShowGad(GadVisibility.Visible);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MajorTypePage(
                                majorType: mts[0],
                              )));
                },
              )),
    );
  }
}

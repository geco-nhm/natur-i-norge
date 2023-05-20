import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/generated/codegen_loader.g.dart';
import 'package:naturinorge_guide/pages/home_page_lib/home_page_button.dart';
import 'package:naturinorge_guide/pages/inference/inference_page.dart'
    if (dart.library.html) 'package:naturinorge_guide/pages/inference/fake_inference.dart';
// import 'package:naturinorge_guide/pages/inference/inference_page.dart';
import 'package:naturinorge_guide/pages/lec/lec_list_page.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type_group_page.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/other/loading.dart';
import 'package:naturinorge_guide/pages/nin_structure/other/loading_overlay.dart';
import 'package:naturinorge_guide/pages/species/species_page.dart';
import 'package:naturinorge_guide/tools/beta_banner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// const _mail_url = 'mailto:miso.torma.dev@gmail.com';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  _show_menu_item(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        _show_about(context);
        break;
      case 1:
        _switch_language(context);
        break;
      default:
    }
  }

  _switch_language(BuildContext context) async {
    if (context.locale.languageCode == 'nb') {
      context.setLocale(Locale('en', 'US'));
    } else {
      context.setLocale(Locale('nb', 'NO'));
    }
    await Provider.of<NinStructureProvider>(context, listen: false)
        .setLocale(context.locale);
    Provider.of<MajorTypeProvider>(context, listen: false)
        .setLocale(context.locale);
  }

  String _get_language_string(BuildContext context) {
    if (context.locale.languageCode == 'nb') {
      return 'English';
    } else {
      return 'Norsk';
    }
  }

  _show_about(BuildContext context) {
    showAboutDialog(
        context: context,
        applicationName: 'Natur i Norge guide',
        applicationIcon: Container(
          height: 150,
          width: 150,
          child: Image.asset(
            'assets/launch_icon/foreground.png',
            width: 150,
            height: 150,
          ),
        ),
        children: [
          Text(
              'Natur i Norge guide er utviklet av Michal Torma i samarbeid med øvrige ansatte ved Geo-økologisk forskningsgruppe, Naturhistorisk museum, Universitetet i Oslo og med Artsdatabanken. Appen er et hjelpemiddel for naturkartleggere i arbeidet med å typifisere norsk natur etter typesystemet Natur i Norge.'),
          Text(
              'Appen ligger nå ute i en testversjon, og inneholder foreløpig kun art-/habitatrelasjoner for utvalgte arter i skogsmark. Datagrunnlaget appen bygger på, er sammenstilt av Rune Halvorsen ved Naturhistorisk museum med bistand fra flere norske fagmiljøer som ledd i arbeidet med utvikling av NiN versjon 2. Dette datagrunnlaget er også tilgjengelig via'),
          ElevatedButton(
            onPressed: () async =>
                await launch('https://artsdatabanken.no/egenskapsbanken'),
            // onPressed: () async => await canLaunch(_mail_url)
            //     ? await launch(_mail_url)
            //     : throw 'Could not launch $_mail_url',
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('artsdatabanken.no'), Icon(Icons.launch)],
            ),
          ),
          Text(
              'Natur i Norge Guide er tilgjengelig for nedlasting som Android- og iOS-app:'),
          ElevatedButton(
            onPressed: () async => await launch('https://l.ead.me/batwGC'),
            // onPressed: () async => await canLaunch(_mail_url)
            //     ? await launch(_mail_url)
            //     : throw 'Could not launch $_mail_url',
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('App link'), Icon(Icons.launch)],
            ),
          ),

          Text(
              'Natur i Norge guide er utviklet av Michal Torma i samarbeid med øvrige ansatte ved Geo-økologisk forskningsgruppe, Naturhistorisk museum, Universitetet i Oslo og med Artsdatabanken.'),
          // ElevatedButton(
          //     onPressed: () async => await launch(_mail_url),
          //     // onPressed: () async => await canLaunch(_mail_url)
          //     //     ? await launch(_mail_url)
          //     //     : throw 'Could not launch $_mail_url',
          //     child: Text('Kontakt os'))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<NinStructureProvider>(context, listen: false).initialize();

    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Natur i Norge guide'),
          bottom: LoadingWidget(),
          actions: [
            BetaBanner(),
            PopupMenuButton<int>(
              itemBuilder: (context) => [
                PopupMenuItem<int>(value: 0, child: Text('Om NiN-Guide')),
                PopupMenuItem<int>(
                    value: 1, child: Text(_get_language_string(context)))
              ],
              onSelected: (idx) => _show_menu_item(context, idx),
            )
          ],
        ),
        body: Stack(
          children: [
            GridView(
              padding: EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  childAspectRatio: 1.618,
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24),
              children: [
                HomePageButton(
                    key: ValueKey('nin_structure_btn'),
                    image: Image.asset('assets/network_icon.png'),
                    text: LocaleKeys.structure.tr(),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MajorTypeGroupPage()))),
                HomePageButton(
                    key: ValueKey('lkm_btn'),
                    image: Image.asset('assets/gradient_icon.png'),
                    text: 'LKM',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LecListPage()))),
                HomePageButton(
                    key: ValueKey('species_btn'),
                    image: Image.asset('assets/species_icon.png'),
                    text: 'Arter',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SpeciesPage()))),
                if (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.android)
                  HomePageButton(
                      key: ValueKey('inference_btn'),
                      image: Image.asset('assets/species_icon.png'),
                      text: 'Inference',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => InferencePage())))
              ],
            ),
            LoadingOverlay(),
          ],
        ),
      ),
    );
  }
}

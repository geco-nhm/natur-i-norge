import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:naturinorge_guide/db/nin_db.dart';
import 'package:naturinorge_guide/pages/home_page.dart';
// import 'package:naturinorge_guide/pages/inference/lib/clasifier.dart';
import 'package:naturinorge_guide/pages/inference/lib/inference_provider.dart'
    if (dart.dart.library.html) 'package:naturinorge_guide/pages/inference/lib/fake_inference_provider.dart';
import 'package:naturinorge_guide/pages/lec/lec_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/major_type/major_type_provider.dart';
import 'package:naturinorge_guide/pages/nin_structure/nin_structure_provider.dart';
import 'package:naturinorge_guide/tools/my_theme.dart';
// import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';

import 'generated/codegen_loader.g.dart';

NiNDatabase? db;
late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await PrefService.init(prefix: 'pref_');
  // PrefService.setDefaultValues({
  //   PREFS_DARK: false,
  //   PREFS_CHILD: false,
  // });
  db = NiNDatabase();
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    cameras = await availableCameras();
  }

  runApp(EasyLocalization(
    child: MyApp(),
    supportedLocales: [Locale('en', 'US'), Locale('nb', 'NO')],
    path: 'local', //'resources/langs',
    fallbackLocale: Locale('nb', 'NO'),
    startLocale: Locale('nb', 'NO'),
    // saveLocale: false,
    // useOnlyLangCode: true,
    // preloaderColor: Colors.black,
    // preloaderWidget: CustomPreloaderWidget(),

    // optional assetLoader default used is RootBundleAssetLoader which uses flutter's assetloader
    // install easy_localization_loader for enable custom loaders
    // assetLoader: RootBundleAssetLoader()
    // assetLoader: HttpAssetLoader()
    // assetLoader: FileAssetLoader()
    // assetLoader: CsvAssetLoader()
    // assetLoader: YamlAssetLoader() //multiple files
    // assetLoader: YamlSingleAssetLoader() //single file
    // assetLoader: XmlAssetLoader() //multiple files
    // assetLoader: XmlSingleAssetLoader() //single file
    // assetLoader: CodegenLoader()
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<NinStructureProvider>(
            create: (_) => NinStructureProvider(context.locale),
            lazy: false,
          ),
          ChangeNotifierProvider<MajorTypeProvider>(
            create: (_) => MajorTypeProvider(context.locale),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => LecProvider(context.locale),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (_) => InferenceProvider(),
            lazy: false,
          ),
        ],
        child: MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            title: LocaleKeys.application_name.tr(),
            themeMode: ThemeMode.light,
            theme: lightTheme,
            // darkTheme: darkTheme,
            home: HomePage()));
  }
}

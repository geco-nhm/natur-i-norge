import 'package:drift/backends.dart';
import 'package:drift/web.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

Future<DelegatedDatabase> getLazyDb() async {
  print("Constructing web database");
  final dbAssetName = 'nin_database.db';
  final dbName = 'nin_85.db';
  final storage = await DriftWebStorage.indexedDbIfSupported(dbName);
  // await MoorWebStorage.volatile();
  return WebDatabase.withStorage(
    storage,
    logStatements: true,
    initializer: () async {
      print('Initializer triggered');
      // Copy from asset
      var data = await rootBundle.load(join('assets', dbAssetName));
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await storage.store(bytes);
      return bytes;
    },
  );
}

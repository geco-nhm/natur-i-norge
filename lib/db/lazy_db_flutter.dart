import 'dart:io';

import 'package:drift/backends.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<DelegatedDatabase> getLazyDb() async {
  final dbFile = await rootBundle.load('assets/nin_database.db');
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'nin3.sqlite'));
  await file.writeAsBytes(dbFile.buffer.asUint8List());
  return NativeDatabase(file);
}

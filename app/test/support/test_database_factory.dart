import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory createTestDatabaseFactory() {
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

Directory createTempDirectory(String prefix) =>
    Directory.systemTemp.createTempSync(prefix);

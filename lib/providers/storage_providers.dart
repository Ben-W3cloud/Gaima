import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../services/storage/chat_dao.dart';

/// Lazily opens the on-device Sqflite store once per app run.
final chatDaoProvider = FutureProvider<ChatDao>((ref) async {
  final db = await openChatDatabase();
  ref.onDispose(() => db.close());
  return ChatDao(db);
});

/// App documents directory (persisted model + database live here).
final documentsDirProvider = FutureProvider<Directory>((ref) async {
  return getApplicationDocumentsDirectory();
});
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/chat_message.dart';
import '../../core/chat_session.dart';

/// Opens the on-device relational store.
Future<Database> openChatDatabase() async {
  final dbPath = await getDatabasesPath();
  return openDatabase(
    p.join(dbPath, 'offline_gemma.sqlite'),
    version: 1,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER NOT NULL,
          role TEXT NOT NULL,
          body TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'CREATE INDEX idx_messages_session ON messages (sessionId, id)');
    },
  );
}

/// DAO encapsulating every session/message read & write.
///
/// All methods are async — callers never block the UI frame on a DB write, and
/// persistence never shares a thread with the inference engine.
class ChatDao {
  final Database _db;
  ChatDao(this._db);

  // ---- Sessions ----------------------------------------------------------

  /// All sessions, newest activity first.
  Future<List<ChatSession>> listSessions() async {
    final rows = await _db.query(
      'sessions',
      orderBy: 'updatedAt DESC, id DESC',
    );
    return rows.map(ChatSession.fromRow).toList();
  }

  Future<int> createSession(String title) async {
    final now = DateTime.now();
    return insertSession(ChatSession(
      title: title,
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<int> insertSession(ChatSession session) async {
    return _db.insert('sessions', session.toRow()..remove('id'));
  }

  Future<void> renameSession(int id, String title) =>
      _db.update('sessions',
          {'title': title, 'updatedAt': DateTime.now().toUtc().toIso8601String()},
          where: 'id = ?', whereArgs: [id]);

  Future<void> touchSession(int id) =>
      _db.update('sessions',
          {'updatedAt': DateTime.now().toUtc().toIso8601String()},
          where: 'id = ?', whereArgs: [id]);

  Future<void> deleteSession(int id) async {
    // Cascade removes the session's messages via FK.
    await _db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Messages ----------------------------------------------------------

  Future<List<ChatMessage>> messagesFor(int sessionId) async {
    final rows = await _db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
    return rows.map(ChatMessage.fromRow).toList();
  }

  Future<int> insertMessage(ChatMessage message) async {
    return _db.insert('messages', message.toRow()..remove('id'));
  }

  Future<void> updateMessageBody(int id, String body) =>
      _db.update('messages', {'body': body}, where: 'id = ?', whereArgs: [id]);
}
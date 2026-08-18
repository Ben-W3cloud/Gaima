/// Chat roles mirrored onto the schema and the inference chat template.
enum Role {
  system,
  user,
  assistant;

  /// Stable DB / JSON string.
  String get wireName {
    switch (this) {
      case Role.system:
        return 'system';
      case Role.user:
        return 'user';
      case Role.assistant:
        return 'assistant';
    }
  }

  static Role fromWire(String value) {
    switch (value) {
      case 'system':
        return Role.system;
      case 'assistant':
        return Role.assistant;
      case 'user':
      default:
        return Role.user;
    }
  }
}

/// A single persisted turn of a conversation.
class ChatMessage {
  final int? id;
  final int sessionId;
  final Role role;
  final String body;
  final DateTime timestamp;

  const ChatMessage({
    this.id,
    required this.sessionId,
    required this.role,
    required this.body,
    required this.timestamp,
  });

  bool get isAssistant => role == Role.assistant;

  Map<String, Object?> toRow() => {
        'id': id,
        'sessionId': sessionId,
        'role': role.wireName,
        'body': body,
        'timestamp': timestamp.toUtc().toIso8601String(),
      };

  factory ChatMessage.fromRow(Map<String, Object?> row) => ChatMessage(
        id: row['id'] as int?,
        sessionId: row['sessionId'] as int,
        role: Role.fromWire(row['role'] as String),
        body: row['body'] as String,
        timestamp:
            DateTime.parse(row['timestamp'] as String).toLocal(),
      );

  ChatMessage copyWith({String? body, int? id}) => ChatMessage(
        id: id ?? this.id,
        sessionId: sessionId,
        role: role,
        body: body ?? this.body,
        timestamp: timestamp,
      );
}
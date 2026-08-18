/// A named, independent conversation. Session isolation is guaranteed by the
/// inference engine holding a per-session KV slot (see InferenceEngine).
class ChatSession {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatSession({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ChatSession.fromRow(Map<String, Object?> row) => ChatSession(
        id: row['id'] as int?,
        title: row['title'] as String,
        createdAt: DateTime.parse(row['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(row['updatedAt'] as String).toLocal(),
      );

  ChatSession copyWith({String? title, DateTime? updatedAt}) => ChatSession(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
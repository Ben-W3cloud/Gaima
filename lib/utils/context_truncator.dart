import '../core/chat_message.dart';
import '../core/model_metadata.dart';

/// OOM guard (Phase 4).
///
/// Sqflite holds the full history permanently, per session. Before each
/// inference call we build a *fresh temporary array* by walking backward from
/// the newest message, token-counting and stopping at the context ceiling.
/// Only this trimmed array — never the DB — reaches the engine. Nothing is ever
/// deleted from visible history.
class ContextTruncator {
  const ContextTruncator({
    this.maxTokens = ModelMetadata.contextTokens,
    int Function(String)? tokenCounter,
  }) : _tokenCounter =
            tokenCounter ?? _defaultEstimateCharactersPer4;

  final int maxTokens;

  /// Swappable token counter. Replace with `Llama.tokenize(...).length` when
  /// running inside the loaded context to get exact counts; the default is a
  /// memory-safe heuristic that needs no FFI model handle.
  final int Function(String) _tokenCounter;

  /// Estimates tokens as roughly one token per four UTF-8 bytes — a solid
  /// approximation for English-language models on trimmed budgets.
  static int _defaultEstimateCharactersPer4(String text) =>
      (text.length / 4).ceil();

  /// Trims [history] (chronological, oldest-first) to the context window,
  /// always keeping the newest user turn so a prompt can still be answered.
  List<ChatMessage> trim(List<ChatMessage> history) {
    if (history.isEmpty) return const [];
    if (history.length == 1) return history;

    var budget = maxTokens;

    final systemBlock =
        history.where((m) => m.role == Role.system).toList()
          ..add(ChatMessage(
            sessionId: history.first.sessionId,
            role: Role.system,
            body: ModelMetadata.systemPrompt,
            timestamp: DateTime.now(),
          ));
    // Dedup by identity to avoid double-counting if a system turn exists.
    final system = <ChatMessage>[];
    final seenSystem = <String>{};
    for (final s in systemBlock) {
      if (seenSystem.add(s.body)) system.add(s);
    }
    budget -= system.fold(0, (sum, s) => sum + _tokenCounter(s.body));
    if (budget <= 0) return [system.last];

    // Walk newest -> oldest reserving space.
    final trimmed = <ChatMessage>[];
    for (var i = history.length - 1; i >= 0; i--) {
      if (history[i].role == Role.system) continue;
      final cost = _tokenCounter(history[i].body);
      // Always keep the newest message even if it overflows slightly.
      if (trimmed.isEmpty || budget - cost >= 0) {
        trimmed.insert(0, history[i]);
        budget -= cost;
      } else {
        break;
      }
    }

    // Never persist the synthetic system turn — it belongs to the engine input.
    final hasSystemTurn = history.any((m) => m.role == Role.system);
    return [...(hasSystemTurn ? system : [system.last]), ...trimmed];
  }
}
/// Central, single source of truth for the bundled model expectations.
///
/// The Gemma-2B Instruct GGUF is intentionally NOT bundled in the APK — it is
/// fetched on first launch from Cloudflare R2 (see README Part 2) and verified
/// against [sha256] before the chat UI unlocks.
class ModelMetadata {
  const ModelMetadata._();

  static const String modelFileName = 'gemma-4-E2B_q4_0-it.gguf';

  /// Cloudflare R2 signed/credentialed download endpoint
  /// (replace with the real bucket URL and checksum before shipping).
  static const String downloadUrl =
      'https://pub-c4e2d2b4a58d4f1a8a6f5a1f3d2c1b0e.r2.dev/gemma-4-E2B_q4_0-it.gguf';

  /// Full expected size in bytes (approx 3.1GB). Used for progress math when
  /// the remote does not advertise Content-Length.
  static const int expectedSizeBytes = 3349516256;

  /// SHA-256 of the expected model artifact. Populate from `certutil -hashfile`
  /// output of the generated GGUF. The download is discarded on mismatch.
  static const String sha256 =
      ' FA401B55B07EE70A54C6DAE3903C783A6E65064312529EA57175CB5F8DEC6634';

  /// Rolling context ceiling — the OOM guard truncates prompts to this.
  static const int contextTokens = 2000;

  /// Single hardcoded system prompt applied to every session (v1 scope).
  static const String systemPrompt = SystemPromptCore.system;

  /// Expected generation budget (0 = unlimited, bounded by context ceiling).
  static const int maxNewTokens = 512;
}

/// Single hardcoded system prompt at index zero for all sessions (v1 scope).
abstract final class SystemPromptCore {
  static const String system =
      'You are a helpful, warm, and honest assistant. Give clear, concise, '
      'and accurate answers. Do not claim abilities you lack.';
}

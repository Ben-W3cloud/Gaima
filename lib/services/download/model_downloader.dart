import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../core/model_metadata.dart';

/// Tracks the live state of a single (possibly resumable) model download.
class DownloadProgress {
  final int received;
  final int? total;
  final double fraction;

  const DownloadProgress({
    required this.received,
    this.total,
    required this.fraction,
  });

  double get smoothFraction => fraction.clamp(0.0, 1.0);
}

/// Result of a completed or failed provisioning pass.
sealed class DownloadResult {}

class DownloadSuccess extends DownloadResult {
  final File file;
  DownloadSuccess(this.file);
}

class DownloadFailure extends DownloadResult {
  final String message;
  DownloadFailure(this.message);
}

/// Downloads the GGUF from R2 with byte-range resume, then verifies it against
/// the bundled SHA-256 before it is accepted for inference.
class ModelDownloader {
  ModelDownloader._();
  static final ModelDownloader instance = ModelDownloader._();

  Dio get _dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      followRedirects: true,
      receiveDataWhenStatusError: true,
    ),
  );

  File partialFile(Directory dir) =>
      File(p.join(dir.path, '${ModelMetadata.modelFileName}.part'));

  File finalFile(Directory dir) =>
      File(p.join(dir.path, ModelMetadata.modelFileName));

  /// True when a verified model already lives in [dir].
  Future<bool> isModelPresent(Directory dir) async {
    final file = finalFile(dir);
    if (!await file.exists()) return false;
    return sha256Matches(file);
  }

  /// Resumable, progressing download. Emits [DownloadProgress] as bytes arrive
  /// and completes when the stream closes (call [finalize] afterwards).
  ///
  /// The `.part` file is kept on error so interrupted runs resume from the last
  /// received byte via an HTTP Range request.
  Stream<DownloadProgress> start(Directory dir) {
    final controller = StreamController<DownloadProgress>();

    Future<void> run() async {
      final partial = partialFile(dir);
      final resumed = await partial.exists() ? await partial.length() : 0;
      final headers = resumed > 0
          ? {'Range': 'bytes=$resumed-'}
          : <String, Object>{};

      try {
        await _dio.download(
          ModelMetadata.downloadUrl,
          partial.path,
          options: Options(headers: headers),
          onReceiveProgress: (received, total) {
            final running = resumed + received;
            // Dio reports total = -1 when Content-Length is absent.
            final totalBytes = total > 0
                ? total
                : resumed + ModelMetadata.expectedSizeBytes;
            if (!controller.isClosed) {
              controller.add(
                DownloadProgress(
                  received: running,
                  total: totalBytes,
                  fraction: running > 0 && totalBytes > 0
                      ? running / totalBytes
                      : 0.0,
                ),
              );
            }
          },
        );
        if (!controller.isClosed) await controller.close();
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    }

    run();
    return controller.stream;
  }

  /// Promotes a verified `.part` to the final path, or clears a bad partial.
  Future<DownloadResult> finalize(Directory dir) async {
    final partial = partialFile(dir);
    if (!await partial.exists()) return DownloadFailure('Download incomplete.');
    if (!await sha256Matches(partial)) {
      await partial.delete();
      return DownloadFailure('Checksum mismatch — model rejected and removed.');
    }
    final target = finalFile(dir);
    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
    return DownloadSuccess(target);
  }

  /// Hex SHA-256 of [file]; empty hex on read error.
  Future<String> sha256Hex(File file) async {
    try {
      final digest = await sha256.bind(file.openRead()).first;
      return digest.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
    } catch (_) {
      return '';
    }
  }

  Future<bool> sha256Matches(File file) async {
    final hex = await sha256Hex(file);
    if (hex.isEmpty) return false;
    return ModelMetadata.sha256.toLowerCase() == hex;
  }
}

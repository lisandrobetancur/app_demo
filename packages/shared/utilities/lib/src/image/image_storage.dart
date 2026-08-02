import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_storage_resolver.dart'
    if (dart.library.io) 'image_storage_resolver_io.dart';

/// Cross-platform product/avatar image persistence.
///
/// Platform difference, documented once here and hidden everywhere else:
///  * **Android / iOS**: the picked image bytes are copied into the app
///    documents directory and the resulting *file path* is stored.
///  * **Web**: there is no file system, so the bytes are stored inline as a
///    base64 *data URI*.
///
/// Both representations are plain strings, so the database schema and every
/// feature stay platform-agnostic.
abstract interface class ImageStorage {
  /// Persists [bytes] under a name derived from [imageId] and returns the
  /// string reference to store in the database (file path or data URI).
  Future<String> save({required Uint8List bytes, required String imageId});

  /// Loads the bytes referenced by [reference], or `null` when missing.
  Future<Uint8List?> load(String reference);

  /// Deletes the stored image when applicable (no-op for data URIs).
  Future<void> delete(String reference);
}

/// Contract provider, overridden by the shell with [createImageStorage].
final Provider<ImageStorage> imageStorageProvider = Provider<ImageStorage>(
  (Ref ref) => throw UnimplementedError('imageStorageProvider'),
);

/// Resolves the platform implementation (conditional import selects the
/// io-backed one on mobile/desktop and the data-URI one on the web).
ImageStorage createImageStorage() => resolveImageStorage();

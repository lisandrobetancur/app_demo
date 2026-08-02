import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'image_storage.dart';

/// Web implementation: images are stored inline as base64 data URIs, because
/// the web has no app-writable file system.
class DataUriImageStorage implements ImageStorage {
  const DataUriImageStorage();

  static const String _prefix = 'data:image/png;base64,';

  @override
  Future<String> save({
    required Uint8List bytes,
    required String imageId,
  }) async => '$_prefix${base64Encode(bytes)}';

  @override
  Future<Uint8List?> load(String reference) async {
    if (!reference.startsWith('data:')) {
      return null;
    }
    final int comma = reference.indexOf(',');
    if (comma < 0) {
      return null;
    }
    return base64Decode(reference.substring(comma + 1));
  }

  @override
  Future<void> delete(String reference) async {
    // Data URIs live inside the database row; nothing else to delete.
  }
}

/// Conditional default: on platforms without `dart:io` (the web) the storage
/// is the data-URI implementation.
ImageStorage resolveImageStorage() => const DataUriImageStorage();

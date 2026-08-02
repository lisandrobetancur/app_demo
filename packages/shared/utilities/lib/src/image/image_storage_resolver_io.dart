import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_storage.dart';

/// Mobile implementation: the picked image bytes are copied into the app
/// documents directory and the file path is stored in the database.
///
/// This file is only reachable through the conditional import in
/// `image_storage.dart`, which is the single sanctioned `dart:io` guard for
/// image persistence.
class FileImageStorage implements ImageStorage {
  const FileImageStorage();

  static const String _folder = 'market_images';

  @override
  Future<String> save({
    required Uint8List bytes,
    required String imageId,
  }) async {
    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory target = Directory(p.join(documents.path, _folder));
    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }
    final File file = File(p.join(target.path, '$imageId.png'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<Uint8List?> load(String reference) async {
    final File file = File(reference);
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String reference) async {
    final File file = File(reference);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// Conditional default: on `dart:io` platforms the storage is file-based.
ImageStorage resolveImageStorage() => const FileImageStorage();

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'coloring_document.dart';

/// Saves each artwork as a small JSON file (vector strokes, not pixels), so a
/// drawing can be resumed at full quality on any screen size.
class ArtworkStorage {
  const ArtworkStorage._();

  static Future<File> _file(String id) async {
    final dir = await _dir();
    return File('${dir.path}/$id.json');
  }

  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/artworks');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Saved artwork ids, newest first.
  static Future<List<String>> list() async {
    try {
      final dir = await _dir();
      final files = <(String, DateTime)>[];
      await for (final e in dir.list()) {
        if (e is File && e.path.endsWith('.json')) {
          final name = e.uri.pathSegments.last;
          files.add((name.substring(0, name.length - 5), await e.lastModified()));
        }
      }
      files.sort((a, b) => b.$2.compareTo(a.$2));
      return [for (final f in files) f.$1];
    } catch (e) {
      debugPrint('list failed: $e');
      return const [];
    }
  }

  static Future<void> delete(String id) async {
    try {
      final f = await _file(id);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('delete failed: $e');
    }
  }

  static Future<void> deleteAll() async {
    try {
      final dir = await _dir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('deleteAll failed: $e');
    }
  }

  static Future<DocState?> load(String id) async {
    try {
      final f = await _file(id);
      if (!await f.exists()) return null;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return DocState.fromJson(json);
    } catch (e) {
      debugPrint('Could not load artwork $id: $e');
      return null;
    }
  }

  /// Atomic write: a crash mid-save never corrupts the previous version.
  static Future<void> save(String id, DocState state) async {
    try {
      final f = await _file(id);
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(state.toJson(id)), flush: true);
      await tmp.rename(f.path);
    } catch (e) {
      debugPrint('Could not save artwork $id: $e');
    }
  }
}

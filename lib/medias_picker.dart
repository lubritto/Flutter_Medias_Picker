import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class MediasPicker {
  static const MethodChannel _channel =
      const MethodChannel('medias_picker');

  static Future<List<dynamic>> pickMedias({@required int quantity, int maxWidth, int quality}) async {

    if (maxWidth != null && maxWidth < 0) {
      throw new ArgumentError.value(maxWidth, 'maxWidth cannot be negative');
    }

    if (quality != null && (quality < 0 || quality > 100)) {
      throw new ArgumentError.value(maxWidth, 'quality cannot be negative and cannot be bigger then 100');
    }

    final List<dynamic> docsPaths = await _channel.invokeMethod('pickMedias', <String, dynamic>{
        'quantity': quantity,
        'maxWidth': maxWidth ?? 0,
        'quality': quality ?? 100,
      });
    return docsPaths;
  }

  static Future<List<dynamic>> compressImages({@required List<String> imgPaths, int maxWidth, int quality}) async {

    if (imgPaths != null && imgPaths.length <= 0) {
      throw new ArgumentError.value(imgPaths, 'imgPaths needs to have 1 or more itens');
    }

    if (maxWidth != null && maxWidth < 0) {
      throw new ArgumentError.value(maxWidth, 'maxWidth cannot be negative');
    }

    if (quality != null && (quality < 0 || quality > 100)) {
      throw new ArgumentError.value(quality, 'quality cannot be negative and cannot be bigger then 100');
    }

    final List<dynamic> docsPaths = await _channel.invokeMethod('compressImages', <String, dynamic>{
      'imgPaths': imgPaths,
      'maxWidth': maxWidth ?? 0,
      'quality': quality ?? 100
    });
    return docsPaths;
  }

  static Future<bool> deleteAllTempFiles() async {
    final bool deleted = await _channel.invokeMethod('deleteAllTempFiles');
    return deleted;
  }
}

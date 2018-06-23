import 'dart:async';

import 'package:flutter/services.dart';

class MediasPicker {
  static const MethodChannel _channel =
      const MethodChannel('medias_picker');

  static Future<List<dynamic>> pickMedias(int quantity, int maxWidth, int quality) async {
    final List<dynamic> docsPaths = await _channel.invokeMethod('pickMedias', <String, dynamic>{
        'quantity': quantity,
        'maxWidth': maxWidth,
        'quality': quality,
      });
    return docsPaths;
  }

  static Future<bool> deleteAllTempFiles() async {
    final bool deleted = await _channel.invokeMethod('deleteAllTempFiles');
    return deleted;
  }
}

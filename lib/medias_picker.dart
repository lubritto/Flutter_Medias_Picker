import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class MediasPicker {
  static const MethodChannel _channel =
      const MethodChannel('medias_picker');

  static Future<List<dynamic>> pickImages({@required int quantity, int maxWidth, int maxHeight, int quality}) async {

    if (maxWidth != null && maxWidth < 0) {
      throw new ArgumentError.value(maxWidth, 'maxWidth cannot be negative');
    }

    if (maxHeight != null && maxHeight < 0) {
      throw new ArgumentError.value(maxHeight, 'maxHeight cannot be negative');
    }

    if (quality != null && (quality < 0 || quality > 100)) {
      throw new ArgumentError.value(maxWidth, 'quality cannot be negative and cannot be bigger then 100');
    }

    if (Platform.isAndroid)
      if (!await checkPermission())
        if (!await requestPermission())
          return [];

    final List<dynamic> docsPaths = await _channel.invokeMethod('pickImages', <String, dynamic>{
        'quantity': quantity,
        'maxWidth': maxWidth ?? 0,
        'maxHeight': maxHeight ?? 0,
        'quality': quality ?? 100,
      });
    return docsPaths;
  }

  static Future<List<dynamic>> pickVideos({@required int quantity}) async {

    if (Platform.isAndroid)
      if (!await checkPermission())
        if (!await requestPermission())
          return [];

    final List<dynamic> docsPaths = await _channel.invokeMethod('pickVideos', <String, dynamic>{
        'quantity': quantity,
      });
    return docsPaths;
  }

  static Future<List<dynamic>> compressImages({@required List<String> imgPaths, int maxWidth, int maxHeight, int quality}) async {

    if (imgPaths != null && imgPaths.length <= 0) {
      throw new ArgumentError.value(imgPaths, 'imgPaths needs to have 1 or more itens');
    }

    if (maxWidth != null && maxWidth < 0) {
      throw new ArgumentError.value(maxWidth, 'maxWidth cannot be negative');
    }

    if (maxHeight != null && maxHeight < 0) {
      throw new ArgumentError.value(maxHeight, 'maxHeight cannot be negative');
    }

    if (quality != null && (quality < 0 || quality > 100)) {
      throw new ArgumentError.value(quality, 'quality cannot be negative and cannot be bigger then 100');
    }

    if (Platform.isAndroid)
      if (!await checkPermission())
        if (!await requestPermission())
          return [];

    final List<dynamic> docsPaths = await _channel.invokeMethod('compressImages', <String, dynamic>{
      'imgPaths': imgPaths,
      'maxWidth': maxWidth ?? 0,
      'maxHeight': maxHeight ?? 0,
      'quality': quality ?? 100
    });
    return docsPaths;
  }

  //Just android (storage permission)
  static Future<bool> checkPermission() async {
    return await _channel.invokeMethod("checkPermission");
  }

  //Just android (storage permission)
  static Future<bool> requestPermission() async {
    return await _channel.invokeMethod("requestPermission");
  }

  static Future<bool> deleteAllTempFiles() async {
    final bool deleted = await _channel.invokeMethod('deleteAllTempFiles');
    return deleted;
  }
}

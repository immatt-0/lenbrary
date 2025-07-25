import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';

class FileUtils {
  static dynamic createFile(String path) {
    if (kIsWeb) {
      return null; // Return null on web, we should use Image.memory instead
    } else {
      return File(path);
    }
  }
}

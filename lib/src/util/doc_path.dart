import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class DocPath {
  static Future<String> getDocPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> joinPath(String jpath) async {
    final directory = await getApplicationDocumentsDirectory();
    final p = path.join(directory.path, jpath);
    if (!await fileIsExists(p)) {
      await Directory(directory.path).create(recursive: true);
    }
    return path.join(directory.path, jpath);
  }

  static Future<bool> fileIsExists(String filePath) async {
    if (File(filePath).existsSync()) {
      return true;
    } else {
      return false;
    }
  }
}
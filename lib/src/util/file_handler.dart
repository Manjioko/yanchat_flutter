// import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'dart:typed_data';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';


class FileStructure {
  String name;
  int size;
  // int byte;
  String path;
  XFile xfile;
  FileStructure({
    required this.name,
    required this.size,
    // required this.byte,
    required this.path,
    required this.xfile
  });

  factory FileStructure.fromJson(Map<String, dynamic> json) {
    return FileStructure(
      name: json['name'],
      size: json['size'],
      // byte: json['byte'],
      path: json['path'],
      xfile: json['xfile']
    );
  }
}



// 获取文件
Future<FileStructure?> getFile(ChatBox chatBox) async {
  try {
    // return File(filePath);
    final fileResult = await FilePicker.platform.pickFiles();
    print('fileResult: $fileResult');
    if (fileResult != null) {
      print('获取文件成功：${fileResult.files.first.name}');
      PlatformFile file = fileResult.files.first;
      return FileStructure(
        name: file.name,
        size: file.size,
        // byte: file.bytes,
        path: file.path ?? '',
        xfile: file.xFile
      );
    } else {
      print('取消获取文件');
      return null;
    }
  } catch (e) {
    print('获取文件失败：$e');
    return null;
  }
}

Future<bool> saveFile(XFile file, ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  // String dirPath = '${appDocDir.path}/$userId/${chatBox.to_table}/Files';
  String folderPath = '${appDocDir.path}/$userId/${chatBox.to_table}/Files';
  Directory customerDir = Directory(folderPath);
  // String filePath = '$dirPath/${chatBox.localFileName}';
  if (!await customerDir.exists()) {
    await customerDir.create(recursive: true);
  }

  try {
    file.saveTo('${customerDir.path}/${chatBox.localFileName}')
    .whenComplete(() {
      // 删除临时文件
      try {
        File(file.path).delete();
      } catch (e) {
        print('删除临时文件失败：$e');
      }
    });
    print('文件保存成功：${customerDir.path}/${chatBox.localFileName}');
    return true;
  } catch (e) {
    print('保存文件失败：$e');
    return false;
  }
}

Future<bool> deleteFile(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/Files/${chatBox.localFileName}';
  try {
    File(filePath).delete();
    return true;
  } catch (e) {
    print('删除文件失败：$e');
    return false;
  }
}
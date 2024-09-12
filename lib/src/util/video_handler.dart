import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 获取视频缩略图
Future<Uint8List?> createVideoThumbnail(XFile video) async {
  try {
    final uint8list = await VideoThumbnail.thumbnailData(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 250, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    );

    return uint8list;
  } catch (e) {
    print('制作视频缩略图失败：$e');
    return null;
  }
}

// 保存视频缩略图
Future<bool> saveVideoThumbnail(XFile video, ChatBox chatBox) async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    final prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId')!;
    // 创建以客户ID命名的文件夹路径
    String folderPath = '${appDocDir.path}/$userId/${chatBox.to_table}/thumbnails';
    Directory customerDir = Directory(folderPath);
    // 如果文件夹不存在，则创建它
    if (!await customerDir.exists()) {
      await customerDir.create(recursive: true);
    }

    // 生成缩略图
    final thumbnail = await createVideoThumbnail(video);

    // 保存缩略图
    File('${customerDir.path}/${chatBox.localFileName}').writeAsBytesSync(thumbnail!);
    print('视频缩略图保存成功');
    return true;
  } catch (e) {
    print('保存视频缩略图失败：$e');
    return false;
  }
}


// 获取视频缩略图
Future<Uint8List?> getVideoThumbnail(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  try {
    return File(filePath).readAsBytesSync();
  } catch (e) {
    print('获取视频缩略图失败：$e');
    return null;
  }
  // return ;
}

// 获取视频缩略图地址
Future<String> getVideoThumbnailPath(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  return filePath;
}

// 删除视频缩略图
Future<bool> deleteVideoThumbnail(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  try {
    File(filePath).delete();
  } catch (e) {
    print('删除缩略图失败：$e');
    return false;
  }
  return true;
}

// 保存视频
Future<bool> saveVideo(XFile video, ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  // 创建以客户ID命名的文件夹路径
  String folderPath = '${appDocDir.path}/$userId/${chatBox.to_table}/Videos';
  Directory customerDir = Directory(folderPath);
  // 如果文件夹不存在，则创建它
  if (!await customerDir.exists()) {
    await customerDir.create(recursive: true);
  }
  // 保存视频
  try {
    video
    .saveTo('${customerDir.path}/${chatBox.localFileName}')
    .whenComplete(() {
      // 删除tmp文件
      try {
        File(video.path).delete();
      } catch (e) {
        print('删除临时文件失败：$e');
      }
    });
  } catch (e) {
    print('保存视频失败：$e');
    return false;
  }
  
  return true;
}

// 获取视频
Future<File?> getVideo(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/Videos/${chatBox.localFileName}';
  try {
    return File(filePath);
  } catch (e) {
    print('获取视频失败：$e');
    return null;
  }
}

// 获取视频地址
Future<String> getVideoPath(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/Videos/${chatBox.localFileName}';
  return filePath;
}

// 删除视频
Future<bool> deleteVideo(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/Videos/${chatBox.localFileName}';
  try {
    File(filePath).delete();
  } catch (e) {
    print('删除视频失败：$e');
    return false;
  }
  return true;
}


// 删除音频文件
Future<bool> deleteAudio(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/Records/${chatBox.localFileName}';
  try {
    File(filePath).delete();
  } catch (e) {
    print('删除音频文件失败：$e');
    return false;
  }
  return true;
}

// 获取音频文件路径
Future<String?> getAudioPath(ChatBox chatBox) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId')!;
  String filePath = '${appDocDir.path}/$userId/${chatBox.to_table}/Records/${chatBox.localFileName}';
  return filePath;
}
// import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'dart:typed_data';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:yanchat01/src/util/box_notifier.dart';
import 'package:yanchat01/src/util/global_type.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:yanchat01/src/util/uuid.dart';
import 'share.dart';
import 'request.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'doc_path.dart';


Future<Uint8List?> compressImage(XFile file) async {
  var result = await FlutterImageCompress.compressWithFile(
    file.path,
    minWidth: 100,  // 调整宽度
    // minHeight: 100, // 调整高度
    quality: 10,    // 调整质量
    format: CompressFormat.jpeg, // 调整格式
  );
  return result;
}

Future<Uint8List?> createAvatar(XFile file) async {
  final result = await ImageCropper.platform.cropImage(
    sourcePath: file.path,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressQuality: 80,
    compressFormat: ImageCompressFormat.jpg,
    maxHeight: 200,
    maxWidth: 200,
  );

  Uint8List? data;
  if (result != null) {
    try {
      data = await result.readAsBytes();
      // 删除缓存
      File(result.path).delete();
    } catch (e) {
      print('头像裁剪失败：$e');
    }
  }
  
  return data;
}

// 保存生成的头像
Future<String> saveAvatar(Uint8List image)  async{
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  // 保存图片
  await File('$appDocDir/avatar_$userId.jpg').writeAsBytes(image);
  print('保存头像：$appDocDir/avatar_$userId.jpg');
  return '$appDocDir/avatar_$userId.jpg';
}


Future<bool> saveImage(XFile image, ChatBox chatBox)  async{
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();

  // 创建以客户ID命名的文件夹路径
  String folderPath = '$appDocDir/$userId/${chatBox.to_table}/Images';
  Directory customerDir = Directory(folderPath);

  // 如果文件夹不存在，则创建它
  if (!await customerDir.exists()) {
    await customerDir.create(recursive: true);
  }

  print('保存图片：${customerDir.path}/${chatBox.localFileName}');
  // 保存图片
  await image.saveTo('${customerDir.path}/${chatBox.localFileName}');
  // 删除缓存
  try {
    File(image.path).delete();
  } catch (e) {
    print('删除缓存失败 picture：$e');
  }
  return true;
}

Future<bool> saveThumbnail(XFile image, ChatBox chatBox)  async{
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  // 创建以客户ID命名的文件夹路径
  String folderPath = '$appDocDir/$userId/${chatBox.to_table}/thumbnails';
  Directory customerDir = Directory(folderPath);

  // 如果文件夹不存在，则创建它
  if (!await customerDir.exists()) {
    await customerDir.create(recursive: true);
  }

  // 保存图片
  // 制作缩略图
  final thumbnail = await compressImage(image);
  File('${customerDir.path}/${chatBox.localFileName}').writeAsBytesSync(thumbnail!);
  return true;
}

// 获取缩略图
Future<Uint8List>? getThumbnail(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  // print("filePath ==>  $filePath, localFileName: ${chatBox.localFileName}");
  return File(filePath).readAsBytesSync();
}

// 获取图片
Future<Uint8List?> getImage(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/Images/${chatBox.localFileName}';
  return File(filePath).readAsBytesSync();
}


// 获取缩略图路径
Future<String?> getThumbnailPath(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  // print("filePath ==>  $filePath");
  return filePath;
}

// 删除缩略图
Future<bool> deleteThumbnail(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  try {
    File(filePath).delete();
  } catch (e) {
    print('删除缩略图失败：$e');
    return false;
  }
  return true;
}

// 获取图片路径
Future<String?> getImagePath(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/Images/${chatBox.localFileName}';
  return filePath;
}

// 删除图片
Future<bool> deleteImage(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/Images/${chatBox.localFileName}';
  try {
    File(filePath).delete();
  } catch (e) {
    print('删除图片失败：$e');
    return false;
  }
  return true;
}

// 将缩略图转换成base64
Future<String?> getBase64Thumbnail(ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  String filePath = '$appDocDir/$userId/${chatBox.to_table}/thumbnails/${chatBox.localFileName}';
  return 'data:image/jpeg;base64,${base64Encode(File(filePath).readAsBytesSync())}';
}

// 将base64转换成缩略图
Future<String?> setbase64ToThumbnail(String base64Data,ChatBox chatBox) async {
  String userId = await Share.instance.getString('userId') ?? '';
  final appDocDir = await DocPath.getDocPath();
  final customerDir = Directory('$appDocDir/$userId/${chatBox.to_table}/thumbnails');

  if (!await customerDir.exists()) {
    await customerDir.create(recursive: true);
  }
  // 将base64转换成图片
  Uint8List image = base64Decode(base64Data);
  // 保存图片
  File('${customerDir.path}/${chatBox.localFileName}').writeAsBytesSync(image);
  // print('成功保存缩略图 =》 ${customerDir.path}/${chatBox.localFileName}');
  return '${customerDir.path}/${chatBox.localFileName}';
}

Future<XFile?> getMediaFromGallery() async {
    final ImagePicker picker = ImagePicker();
    // Pick singe image or video.
    final XFile? media = await picker.pickMedia();
    print("路径：${media?.path}");
    return media;
}

// 从相机中获取图片
Future<XFile?> getImageFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source:   ImageSource.camera);
  return image;
}


// 头像下载
Future<String> setAvatar(String friendUserId, BuildContext context, {Function? callback}) async {

    final baseUrl = await Share.instance.getString('baseUrl') ?? '';
    final userId = await Share.instance.getString('userId') ?? '';
    if (baseUrl.isEmpty || userId.isEmpty) {
      print('获取基础信息失败 ==> baseUrl: $baseUrl  userId: $userId');
      return '';
    }

    final boxNotifier = BoxNotifier.instance.box(context);
    final uid = Uid.instance.v4;
    final savePath = await DocPath.joinPath('$userId/avatars/avatar_${friendUserId}_$uid.jpg');
    final downloadPath = '$baseUrl/avatar/avatar_$friendUserId.jpg'; 
    final dio = Request.instance.dio;

    final seachPath = await DocPath.joinPath('$userId/avatars/avatar_$friendUserId');
    final avatarList = await queryAvatarTable(userId, friendUserId, seachPath);

    if (avatarList.isNotEmpty) {
      boxNotifier.avatarMap[friendUserId] = avatarList[0]['avatar_url'];
      return avatarList[0]['avatar_url'];
    }

    try {
      final res = await dio.download(downloadPath, savePath);
      if (res.statusCode == 200) {
        await insertOrUpdateAvatarTable(userId, friendUserId, savePath);
        boxNotifier.avatarMap[friendUserId] = savePath;
        if (callback != null) {
          callback();
        }
        // print('下载头像成功：$savePath');
      } else {
        boxNotifier.avatarMap[friendUserId] = 'images/default_avatar.png';
        print('网络下载失败：$res');
      }
    } catch (e) {
      boxNotifier.avatarMap[friendUserId] = 'images/default_avatar.png';
      // print('下载头像失败：$e');
    }
    return savePath;
}

Future<String> updateAvatar(String friendUserId, BuildContext context) async {

  // 删掉数据库数据
  final userId = await Share.instance.getString('userId') ?? '';
  try {
    final appDocDir = await DocPath.getDocPath();
    final oldAvatarUrlList = await queryAvatarTable(userId, friendUserId, '$appDocDir/$userId/avatars/avatar_$friendUserId');
    final oldAvatarUrl = oldAvatarUrlList[0]['avatar_url'];
    final boxNotifier = BoxNotifier.instance.box(context);
    // 删除旧头像
    await deleteAvatarTable(userId, friendUserId);
    // 删除本地旧头像
    if (File(oldAvatarUrl).existsSync()) {
      File(oldAvatarUrl).deleteSync();
    }
    // 清空缓存
    boxNotifier.deleteAvatarMap(friendUserId);
    // 插入新头像
    await setAvatar(friendUserId, context);
    return 'ok';
  } catch (e) {
    print('删除头像失败 ** ：$e');
    return 'ok';
  }
}
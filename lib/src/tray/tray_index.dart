import 'package:flutter/material.dart';
import 'package:yanchat01/src/file/file_methods.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/util/uuid.dart';
import 'package:yanchat01/src/util/video_handler.dart';
import 'package:yanchat01/src/util/image_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanchat01/src/util/upload.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:yanchat01/src/util/file_handler.dart';

class Tray extends StatefulWidget {
  final Function(bool?) onToggleTray;
  final FriendsListStructure friend;
  final Function() scrollToBottom;
  const Tray(
      {super.key,
      required this.onToggleTray,
      required this.scrollToBottom,
      required this.friend});

  @override
  State<Tray> createState() => _TrayState();
}

class _TrayState extends State<Tray> {
  @override
  void initState() {
    super.initState();
  }

  String jugeType(String filePath, String? mediaType) {
    String fileExtension = filePath.split('.').last.toLowerCase();
    if (mediaType != null) {
      print('mediaType:$mediaType');
      if (mediaType.startsWith('image/')) {
        // print('这是一个图片文件');
        return 'image';
      } else if (mediaType.startsWith('video/')) {
        // print('这是一个视频文件');
        return 'video';
      }
      return 'file';
    } else {
      // 如果mimeType为null，根据扩展名判断
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileExtension)) {
        // print('这是一个图片文件');
        return 'image';
      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(fileExtension)) {
        // print('这是一个视频文件');
        return 'video';
      } else {
        return 'file';
      }
      // return '';
    }
  }

  void _sendMedia({type = 'gallery'}) async {
    final boxDataNotifier =
        Provider.of<BoxDataNotifier>(context, listen: false);
    ChatBox chatBox = ChatBox.fromJson({
      'type': '',
      'text': '',
      'user': 0,
      'time': formatDate(
          DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]),
      'chat_id': Uid.instance.v4,
      'quote': '',
      'to_table': widget.friend.chat_table,
      'to_id': widget.friend.user_id,
      'user_id': '',
      'loading': false,
      'src': '',
      'thumbnail': '',
      'destroy': false,
      'fileName': '',
      'localFileName': '',
      'size': '',
    });
    XFile? media;
    if (type == 'gallery') {
      try {
        media = await getMediaFromGallery();
        // print("文件名是什么: ${media?.name}");
      } catch (e) {
        print('getMediaFromGallery 报错: $e');
      }
    } else if (type == 'camera') {
      media = await getImageFromCamera();
    } else {
      final fileData = await getFile(chatBox);
      if (fileData != null) {
        media = fileData.xfile;
        chatBox.size = byteCovert(fileData.size);
        chatBox.fileName = fileData.name;
      } else {
        print('没有文件');
        return;
      }

    }
    if (media == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final baseUrl = prefs.getString('baseUrl') ?? '';

    chatBox.type = jugeType(media.path, media.mimeType);
    chatBox.fileName = media.name; // 文件名
     // 后缀名
    final lastsuffix = media.name.split('.').last.toLowerCase();
    chatBox.localFileName = '${Uid.instance.v4}.$lastsuffix';
    chatBox.user_id = userId;

    if (userId.isEmpty) return;

    if (jugeType(media.path, media.mimeType).contains('video')) {
      print('视频路径：${media.path}');
      chatBox.text = '[视频]';
      // 视频
      await saveVideoThumbnail(media, chatBox);
      saveVideo(media, chatBox);
    } else if(jugeType(media.path, media.mimeType).contains('image')) {
      chatBox.text = '[图片]';
      // 图片
      await saveThumbnail(media, chatBox);
      saveImage(media, chatBox);
    } else {
      chatBox.text = '[文件] ${chatBox.fileName}';
      // 文件
      saveFile(media, chatBox);
    }

    boxDataNotifier.addBoxList(chatBox, isFirst: true);
    // 插入数据库中
    insertChatTable(widget.friend.chat_table, chatBox);
    for (int index = 0; index < boxDataNotifier.boxList.length; index++) {
      final e = boxDataNotifier.chatList[index];
      if (e.user_id == widget.friend.user_id) {
        // if (chatBox.text.isNotEmpty && chatBox.text.length > 20) {
        //   e.chat = '${chatBox.text.substring(0, 20)}...';
        // } else {
        //   e.chat = chatBox.text;
        // }
        e.chat = chatBox.text;
        e.time = chatBox.time;
        boxDataNotifier.updateChatListData(index, e);
        break;
      }
    }

    // 发送成功消息
    sendSuccessTip(ChatBox chatBox) {
      final uploadSuccessTips = {
        'to_id': chatBox.to_id,
        'user_id': chatBox.user_id,
        'to_table': chatBox.to_table,
        'messages_type': 'uploadSuccess',
        'messages_box': {
          'uploadState': 'success',
          'progress': 100,
          'response': chatBox.response,
          'chat_id': chatBox.chat_id,
          'src': '$baseUrl/source/${chatBox.response}',
          'to_table': chatBox.to_table
        }
      };
      boxDataNotifier.ws?.add(jsonEncode(uploadSuccessTips));
    }

    // 上传到服务器
    mediaUpload(File(media.path),
        (String? err, int? percent, String? responseName) {
      if (responseName != null) {
        // print('上传成功，文件名称是 $responseName');

        if (chatBox.type == 'file') {
          chatBox.response = responseName;
          boxDataNotifier.ws?.add(jsonEncode(chatBox.toJson()));
          boxDataNotifier.updateBoxListByChatId(chatBox);
          sendSuccessTip(chatBox);
          return;
        }

        // 获取缩略图
        getBase64Thumbnail(chatBox).then((data) {
          if (data != null) {
            chatBox.thumbnail = data;
            chatBox.response = responseName;
            boxDataNotifier.updateBoxListByChatId(chatBox);
            boxDataNotifier.ws?.add(jsonEncode(chatBox.toJson()));

            // 上传成功提示
            sendSuccessTip(chatBox);
            // print('上传成功提示：${jsonEncode(uploadSuccessTips)}');
          }
        });
        return;
      }
      if (percent != null) {
        print('上传进度 $percent');
        // 将进度发到后端
        return;
      }
      if (err != null) {
        print('上传失败: $err');
        return;
      }
    });
    // 更新到聊天列表 数据库
    widget.scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.bounceOut,
      height: 300, // 托盘高度
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
              child: GestureDetector(
                  onTap: () => _sendMedia(type: 'gallery'),
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: const Icon(
                          Icons.photo,
                          size: 30,
                        ),
                      ),
                      const Text(
                        '相册',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromARGB(255, 57, 57, 57)),
                      ),
                    ],
                  ))),
          Expanded(
              child: GestureDetector(
            onTap: () => _sendMedia(type: 'camera'),
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: const Icon(
                    Icons.camera,
                    size: 30,
                  ),
                ),
                const Text(
                  '拍摄',
                  style: TextStyle(
                      fontSize: 16.0, color: Color.fromARGB(255, 57, 57, 57)),
                ),
              ],
            ),
          )),
          Expanded(
              child: GestureDetector(
            onTap: () => _sendMedia(type: 'file'),
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 10.0),
                  child: const Icon(
                    Icons.file_present_sharp,
                    size: 30,
                  ),
                ),
                const Text(
                  '选择文件',
                  style: TextStyle(
                      fontSize: 16.0, color: Color.fromARGB(255, 57, 57, 57)),
                ),
              ],
            ),
          ))
          // Add more options as needed
        ],
      ),
    );
  }
}

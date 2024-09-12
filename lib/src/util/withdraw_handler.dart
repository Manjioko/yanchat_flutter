// 撤回功能分为三部分
// 第一部分，从内存中删除自己发送的消息
// 第二部分， 从数据库中删除自己的消息（聊天框和聊天列表是不同的两个表）
// 第三部分，通知客户端删除自己的消息

// 我们先要实现本地客户端的撤回功能，即实现前两个目标
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/util/video_handler.dart';
import 'package:yanchat01/src/util/image_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanchat01/src/util/file_handler.dart';


Future<bool> withdrawHandler(ChatBox? data, BuildContext context) async{
  if (data == null) {
    print('消息为空，无法撤回');
    return false;
  }

  final chatId = data.chat_id;

  final tableName = data.to_table;
  if (tableName.isEmpty) {
    print('消息表名为空，无法撤回');
    return false;
  }

  // 如果是媒体文件，需要删除本地媒体文件
  if (
      (data.type ?? '').contains('video') ||
      (data.type ?? '').contains('image') ||
      (data.type ?? '').contains('audio') ||
      (data.type ?? '').contains('file')
    ) {
    // final type = (data.type ?? '').contains('video') ? 'video' : 'image';
    // String? type;
    // if (data.type?.contains('video') ?? false) {
    //   type = 'video';
    // } else if (data.type?.contains('image') ?? false) {
    //   type = 'image';
    // } else if (data.type?.contains('audio') ?? false) {
    //   type = 'audio';
    // } else if (data.type?.contains('file') ?? false) {
    //   type = 'file';
    // } else {
    //   type = 'text';
    // }
    final isDel = await deleteMediaFile(data,);
    if (!isDel) {
      print('删除媒体文件失败，无法撤回');
      return false;
    }
  } else {
    if (data.type != 'text') {
      print('消息类型不是媒体文件和文本类型，无法撤回, type：${data.type}');
      return false;
    }
  }

  try {
    deleteChatTable(tableName, chatId);
  } catch (e) {
    print('删除消息失败：$e');
    return false;
  }

  // 删除内存的记录
  final boxchatData = Provider.of<BoxDataNotifier>(context, listen: false);

  boxchatData.deleteBoxListByChatId(tableName, chatId);

  final prefs = await SharedPreferences.getInstance();
  final activeId = prefs.getString('activeId');
  final userId = prefs.getString('userId');
  final withdrawBox = data;
  withdrawBox.thumbnail = '';
  withdrawBox.text = '[撤回一条消息]';
  // final isSelf = userId == data.user_id;
  
  // 通知服务器我要撤回消息
  final params = {
    'messages_type': 'withdraw',
    'messages_box': data,
    'to_id': data.to_id,
    'user_id': userId ?? '',
    'to_table': activeId ?? '',
  };

  boxchatData.ws?.add(jsonEncode(params));

  // 更新聊天列表
  final chaListData = boxchatData.getChatListByChatTable(data.to_table);
  if (chaListData != null) {
    chaListData.chat = '[撤回一条消息]';
    boxchatData.updateChatListByChatTable(data.to_table, chaListData);
    // 数据库更新
    updateChatList(chaListData);
  } else {
    print('删除消息失败，无法更新聊天列表');
  }
  return true;
}

Future<bool> deleteMediaFile(ChatBox data) async {
  print("删除媒体文件 ${data.type}");
  if (data.localFileName == null) {
    print('文件名为空，无法删除');
    return false;
  }
  try {
    if (data.type?.contains('video') ?? false) {
      // 删除视频缩略图
      final isDelThumb = await deleteVideoThumbnail(data);
      var isDel = false;
      // user == 1 表示这是客户端发送的视频，目前没有放到本地
      // 所以不需要删除
      if (data.user == 1) {
        isDel = true; 
      } else {
        isDel = await deleteVideo(data);
      }
      return isDel && isDelThumb;
    } else if (data.type?.contains('audio') ?? false) {
      final isDel = await deleteAudio(data);
      return isDel;

    } else if (data.type?.contains('image') ?? false) {
      // 删除图片
      final isDel =  await deleteThumbnail(data);
      return isDel;
    } else {
      // 删除文件
      final isDel = await deleteFile(data);
      return isDel;
    }
  } catch (e) {
    print('删除媒体文件失败：$e');
    return false;
  }
}
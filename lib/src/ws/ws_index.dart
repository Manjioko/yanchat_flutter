import 'dart:io';
// import 'package:flutter/material.dart';
import 'package:flutter_web_socket/flutter_web_socket.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'dart:convert';
import 'dart:async';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/util/doc_path.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/image_handler.dart';
import 'package:yanchat01/src/util/request.dart';
import 'package:yanchat01/src/util/uuid.dart';
import 'package:yanchat01/src/util/share.dart';
import 'package:yanchat01/src/util/withdraw_handler.dart';

class Ws {
  WebSocket? _socket;
  int _retryCount = 0;
  final int _maxRetries = 10; // 最大重试次数
  final Duration _timeDuration = const Duration(seconds: 3); // 重试间隔
  BoxDataNotifier boxDataNotifier;

  Ws({required this.boxDataNotifier});

  // final wsUrl = 'ws://192.168.9.99:9999/';
  // final boxChatNotifier = Provider.of<BoxDataNotifier>(contex, listen: false);

  void connect() async {
    // final prefs = await SharedPreferences.getInstance();
    final wsUrl = await Share.instance.getString('baseWsUrl') ?? '';
    var userInfo = await queryUserInfo(null);
    if (userInfo.isNotEmpty) {
      var token = userInfo[0]['auth'];
      var userId = userInfo[0]['userId'];
      try {
        _socket = await connectToWebSocket(
                socketUrl:
                    '$wsUrl?user_id=$userId&token=${json.decode(token)['refreshToken']}')
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('连接超时');
        });
        if (_socket == null) {
          print('Websocket 连接失败');
          boxDataNotifier.setConnecteStatus('连接失败');
          return reconnect();
        }
        boxDataNotifier.setWebsocket(_socket!);
        _socket!.listen(onData,
            onError: onError, onDone: onDone, cancelOnError: true);

        if (_socket != null) {
          _socket?.pingInterval = const Duration(seconds: 10);
        }
        boxDataNotifier.setConnecteStatus('连接成功');
        _retryCount = 0;

        try {
          getHistoryMessage(userId);
        } catch (e) {
          print(
              '获取历史消息失败 =>: $e, token: ${json.decode(token)['refreshToken']}');
        }
      } catch (e) {
        print('连接失败：$e');
        reconnect();
      }
    }
  }

  void reconnect() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('尝试重新连接...第 $_retryCount 次');
      boxDataNotifier.setConnecteStatus('正在重连=>第 $_retryCount 次');
      Timer(_timeDuration, connect);
    } else {
      print('超过最大重试次数，停止重试');
      boxDataNotifier.setConnecteStatus('连接超时，停止重试');
    }
  }

  void onData(dynamic data) async {
    dynamic chat = jsonDecode(data);
    // final prefs = await SharedPreferences.getInstance();

    print('收到消息：$chat');
    switch (chat['receivedType']) {
      case 'pong':
        if (chat['receivedType'] == 'pong') {
          // print('收到回执 $chat');
        }
        break;
      case 'tips':
        // print("收到提示:$chat");
        _handleTip(chat['data']);
        break;
      case 'progress':
        // print("收到进度:$chat%");
        _handleProgress(chat);
        break;
      default:
        handleMessages(chat);
        break;
    }
  }

  void onError(dynamic err) {
    boxDataNotifier.setConnecteStatus('连接错误');
    reconnect();
    print('socket 错误:$err');
  }

  void onDone() {
    boxDataNotifier.setConnecteStatus('断开连接');
    reconnect();
    print('socket 断开');
  }

  // 回执
  void echo(ChatBox chat) {
    Map<String, dynamic> echo = {
      'user_id': chat.to_id,
      'to_id': chat.user_id,
      'to_table': chat.to_table,
      'chat_id': chat.chat_id,
      'pingpong': 'pong',
      'id': chat.id ?? '',
    };
    // print('回执: ${jsonEncode(echo)}');
    _socket!.add(jsonEncode(echo));
  }

  Future handleMessages(Map<String, dynamic> chat, {bool handleUnread = false}) async {
    // print('收到消息发送过来的消息：$chat');
    var chatBox = ChatBox.fromJson(chat);

    // print('收到消息发送过来的消息 chatBox chat id => ：${chatBox.chat_id}');

    // 收到消息就需要回执，因为处理消息是异步的，所以为了尽快让对方收到确认
    // 不要等到数据库都写完，先回执
    echo(chatBox);

    // 接收到的消息肯定不是自己发送的，所以要把 user 设置为1（表示别人）0表示自己
    chatBox.user = 1;

    // 把数据存入数据库
    chatBox.text = chatBox.text.trim();
    // final prefs = await SharedPreferences.getInstance();
    final active = await Share.instance.getString('activeId') ?? '';
    if (active == chatBox.to_table) {
      boxDataNotifier.addBoxList(chatBox, isFirst: true);
    }
    try {
      // 处理图片或者视频的情况
      await _handleMedia(chatBox);
      print("fileName 插入数据库中: ${chatBox.localFileName}");
      await insertChatTable(chatBox.to_table, chatBox);
    } catch (e) {
      print('插入数据库失败：$e');
      await createChatTable(chatBox.to_table);
      await insertChatTable(chatBox.to_table, chatBox);
    }

    final friendUserId = chatBox.user_id;

    for (var i = 0; i < boxDataNotifier.chatList.length; i++) {
      if (boxDataNotifier.chatList[i].user_id == friendUserId) {
        final chatListData = boxDataNotifier.chatList[i];
        chatListData.chat = json.encode(chatBox.text).replaceAll(RegExp(r'[\\n || \"]'), '');
        // 处理未读消息
        if (active != chatListData.chat_table && !handleUnread) {
          chatListData.unread = chatListData.unread! + 1;
          boxDataNotifier.addTotalUnread(1);
        }
        chatListData.time = chatBox.time;
        // 更新
        boxDataNotifier.updateChatListData(i, chatListData);

        // 更新到数据库
        await updateChatList(chatListData);
        break;
      }
    }
  }

  _handleMedia(ChatBox chatBox) async {
    if (chatBox.type != 'text') {
      // 这种情况下就是图片或者视频
      // 先取出Base64保存到本地
      final base64Data = chatBox.thumbnail ?? '';
      if (base64Data.isNotEmpty) {
        final data = base64Data.replaceAll('data:image/jpeg;base64,', '');
        // 将文件名加入一个随机后缀
        final uid = Uid.instance.v4;
        // 提取出文件名中的文件类型
        final type = chatBox.fileName?.split('.').last.toLowerCase() ?? '';
        chatBox.localFileName = '$uid.$type';
        boxDataNotifier.updateBoxListByChatId(chatBox);
        // 保存
        print('保存到本地：${chatBox.localFileName}');
        await setbase64ToThumbnail(data, chatBox);
        //  saveImage(media, chatBox);
      } else {
        print("type is ${chatBox.type}");
      }
      saveAudio(chatBox);
    }
  }

  // 如果是语音，需要保存到本地
  void saveAudio(ChatBox chatBox) async {
    if (chatBox.type == 'audio/mp3') {
      print('是语音 => ${chatBox.toJson()}');
      // 保存到本地
      DocPath.getDocPath().then((path) async {
        // print('path：$path');
        final savePath = await DocPath.joinPath('${await Share.instance.getString('userId')}/${chatBox.to_table}/Records/${chatBox.localFileName}');
        print('savePath：$savePath');
        // /$userId/$toTable/Records
        Request.instance.dio.download(chatBox.src!, savePath);
      });
    }
  }

  _handleProgress(Map<String, dynamic> chat) {
    // final progressData = json.decode(chat['data']);
    // print('进度数据：${chat['data']['progress']}, ${['progress'] is String}');
    // if (chat['data']['progress'] != null && chat['data']['progress'] == 100) {
    //   final progress = chat['data']['progress'];
    //   print('chat_id：${chat['data']['chat_id']}');

    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //      for (var box in boxDataNotifier.boxList) {
    //       print('chat_id：${chat['data']['chat_id']} == ${box.chat_id}');
    //       if (box.chat_id == chat['data']['chat_id']) {

    //         box.progress = progress as int;
    //         box.response = chat['data']['response'];
    //         print('进度 100%：${box.progress}');
    //         boxDataNotifier.updateBoxListByChatId(box);

    //         break;
    //       }
    //     }
    //   });
    //   // print('进度 100%：${progress is String}');
    // }
  }

  void _handleTip(List<dynamic> data) async {

    // print('收到消息：${data.length}');
    for (var i = 0; i < data.length; i++) {
      switch (data[i]['messages_type']) {
        case 'uploadSuccess':
          _handleRemoteUploadFileToServerSuccess(data[i]);
          break;
        case 'withdraw':
          _handleRemoteWithdraw(data[i]);
          break;
      }
    }


    final userId = await Share.instance.getString('userId') ?? '';
    // 处理完tips后，需要清空服务器端的消息
    // const user_id = sessionStorage.getItem('user_id') || '';
    // 清空消息
    final params = {
      'messages_type': 'clear',
      'to_id': userId,
      'user_id': userId,
      'to_table': 'tips_messages'
    };
    _socket?.add(jsonEncode(params));
  }

  _handleRemoteUploadFileToServerSuccess(dynamic data) async {
    // print('上传成功 ***：${data['messages_box']}');
    final messagesBox = json.decode(data['messages_box']);
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
      
    // });
    for (var box in boxDataNotifier.boxList) {
      if (box.chat_id == messagesBox['chat_id']) {
        box.progress = 100;
        box.src = messagesBox['src'];
        box.response = messagesBox['response'];
        boxDataNotifier.updateBoxListByChatId(box);
        // 更新到数据库
        updateChatTable(box.to_table, box);
        print("上传成功：${box.src}");
        break;
      }
    }
    if (await Share.instance.getString('activeId') != messagesBox['to_table']) {
      final list = await queryChatTable(messagesBox['to_table'], messagesBox['chat_id']);
      if (list.isNotEmpty) {
        try {
          final box = ChatBox.fromJson(list[0]);
          box.progress = 100;
          box.src = messagesBox['src'];
          box.response = messagesBox['response'];
          updateChatTable(box.to_table, box);
          print("上传成功没有进入聊天界面：${box.src}");
        } catch (e) {
          print('更新数据库失败：$e');
        }
      }
    }
  }

  void _handleRemoteWithdraw(dynamic data) async {
    // 撤回消息时，没有撤回媒体文件
    // print('收到撤回消息 ：$data');
    final messagesBox = json.decode(data['messages_box']);
    for (var box in boxDataNotifier.boxList) {
      if (box.chat_id == messagesBox['chat_id']) {
        final chatListdata = boxDataNotifier.getChatListByChatTable(box.to_table);
        if (chatListdata != null) {
          chatListdata.chat = '[撤回一条消息]';
          chatListdata.time = box.time;
          boxDataNotifier.updateChatListByChatTable(box.to_table, chatListdata);
          updateChatList(chatListdata);
        }
        boxDataNotifier.deleteBoxListByChatId(box.to_table, box.chat_id);
        // 更新到数据库
        deleteChatTable(box.to_table, box.chat_id);
        break;
      }
    }
    if (boxDataNotifier.boxList.isEmpty ||
        boxDataNotifier.boxList[0].to_table != messagesBox['to_table']) {
      final list =
          await queryChatTable(messagesBox['to_table'], messagesBox['chat_id']);
      if (list.isNotEmpty) {
        try {
          final box = ChatBox.fromJson(list[0]);
          deleteChatTable(box.to_table, box.chat_id);
        } catch (e) {
          print('删除消息失败：$e');
        }
      }
    }
    // withdrawHandler(data, context)
    if (messagesBox['type'] == 'audio/mp3') {
      try {
        deleteMediaFile(messagesBox);
      } catch (e) {
        print('删除媒体文件失败000：$e');
      }
    }
  }

  Future setChatList(
      FriendsListStructure friend, Map<String, dynamic> data) async {
    final len = data['chat'].length;
    final chat = data['chat'][len - 1]['text'];

    final str = json.encode(chat).replaceAll(RegExp(r'[\\n || \"]'), '');
    // print('chat: $str');
    var c = str;
    // if (str.length < 20) {
    //   c = str;
    // } else {
    //   c = '$str...';
    // }
    final chatListStructure = ChatListStructure(
        user_id: friend.user_id,
        user: friend.user,
        phone_number: friend.phone_number,
        db_version: friend.db_version,
        avatar_url: friend.avatar_url,
        is_use_md: friend.is_use_md,
        created_at: friend.created_at,
        updated_at: friend.updated_at,
        chat_table: friend.chat_table,
        chat: c,
        time: '',
        unread: data['unread'] ?? 0,
        read: 0,
        silent: 0);
    await insertChatList(chatListStructure);
    boxDataNotifier.addChatList(chatListStructure);
    for (var e in data['chat']) {
      if (data['unread'] != null && data['unread'] > 0) {
        // 如果不让 handleMessages 处理未读消息,就需要自己手动处理 totalUnread
        boxDataNotifier.addTotalUnread(1);
        await handleMessages(e, handleUnread: true);
      }
    }
  }

  Future changeChatList(List<ChatListStructure> chatList,
      Map<String, dynamic> data, FriendsListStructure f) async {
    for (var c = 0; c < chatList.length; c++) {
      if (chatList[c].chat_table == f.chat_table) {
        // 处理未读消息
        chatList[c].unread = ((chatList[c].unread ?? 0) +
            (data[f.chat_table]['unread'] ?? 0)) as int?;

        final len = data[f.chat_table]['chat'].length;
        final chat = data[f.chat_table]['chat'];
        final text = chat[len - 1]['text'];
        if (text != null) {
          final str = json.encode(text).replaceAll(RegExp(r'[\\n || \"]'), '');
          chatList[c].chat = str;
        }
        // 更新
        boxDataNotifier.updateChatListData(c, chatList[c]);
        // 更新到数据库
        await updateChatList(chatList[c]);
        for (var c in chat) {
          if (data[f.chat_table]['unread'] != null &&
              data[f.chat_table]['unread'] > 0) {
            // 如果不让 handleMessages 处理未读消息,就需要自己手动处理 totalUnread
            boxDataNotifier.addTotalUnread(1);
            await handleMessages(c, handleUnread: true);
          }
        }
      }
    }
  }

  void getHistoryMessage(String userId) async {
    final friendsData = await queryFriendsList(null);
    final tableList = friendsData.map((e) => e['chat_table']).toList();
    // var prefs = await SharedPreferences.getInstance();
    var baseUrl = await Share.instance.getString('baseUrl') ?? '';

    // final dio = Dio();
    // dio.options.headers['Authorization'] = 'Bearer $token';
    Request.instance.dio.post('$baseUrl/unread',
        data: {'friends': tableList, 'user_id': userId}).then((response) async {
      final chatList = boxDataNotifier.chatList;

      for (var f in friendsData) {
        final friend = FriendsListStructure.fromJson(f);
        if (response.data[friend.chat_table] != null) {
          // 看下聊天列表存在没有
          if (!chatList.any((e) => e.chat_table == friend.chat_table)) {
            await setChatList(friend, response.data[friend.chat_table]);
          } else {
            await changeChatList(chatList, response.data, friend);
          }
        }
      }

      // 等获取历史记录操作完成后再进行tips更新
      // 因为 tips 内容更新包括用户断线是时，对
      // 掉线内容的的操作，而掉线内容全部保存在 history 表中
      // 所以需要想 history 再 tips
      getTips();
    }).catchError((e) {
      print("获取历史消息失败 => $e");
    });
  }

  void getTips() async {
    Request
    .instance
    .dio
    .post(
      '${await Share.instance.getString('baseUrl') ?? ''}/getTips',
      data: {
        'user_id': await Share.instance.getString('userId') ?? '',
    });
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yanchat01/src/util/global_type.dart';


// 定义一个 Box 数据需要共享的数据模型
class BoxDataNotifier extends ChangeNotifier {
  // 登陆判断
  // bool isLogin = false; // 登陆状态

  UserInfo? userInfo; // 用户信息
  WebSocket? ws; // websocket
  List<ChatListStructure> chatList = []; // 聊天列表
  List<ChatBox> boxList = []; // 聊天记录
  List<FriendsListStructure> friends = []; // 好友列表
  String connecteStatus = '未连接';// 连接状态
  Map<String, String> avatarMap = {}; // 头像映射
  int totalUnread = 0; // 总未读消息数
  Map<String, Uint8List?> avatarFileMap = {}; // 头像文件映射
  
  void setLogOut() {
    userInfo = null;
    notifyListeners();
  }

  void setLogIn(UserInfo userInfo) {
    this.userInfo = userInfo;
    notifyListeners();
  }

  bool setWebsocket(WebSocket? socket) {
    if (socket == null) {
      return false;
    }
    ws = socket;
    notifyListeners();
    return true;
  }

  WebSocket? getWebsocket() {
    return ws;
  }

  // 添加聊天记录
  setBoxList(List<ChatBox> list) {
    boxList = list;
    notifyListeners();
  }

  List<ChatBox> getBoxList() {
    return boxList;
  }

  // 添加聊天记录
  void addBoxList(ChatBox list, {bool isFirst = false}) {
    if (isFirst == true) {
      boxList.insert(0, list);
    } else {
      boxList.add(list);
    }
    notifyListeners();
  }
  void updateBoxListByChatId(ChatBox data) {
    // print('原始数据：$data');
    int index = boxList.indexWhere((element) => element.chat_id == data.chat_id);
    if (index != -1) {
      // print('更新到了boxList ：$data');
      boxList[index] = data;
      notifyListeners();
    }
  }

  // 删除聊天记录
  void deleteBoxListByChatId(String tableName, String chatId) {
    boxList.removeWhere((element) => element.to_table == tableName && element.chat_id == chatId);
    notifyListeners();
  }

  // 添加好友列表信息
  void setFriendsList(List<FriendsListStructure> list) {
    friends = list;
    notifyListeners();
  }

  // 添加好友列表信息（单个推入）
  void addFriendList(FriendsListStructure value) {
    friends.add(value);
    notifyListeners();
  }

  // 设置聊天好友列表
  void setChatList(List<ChatListStructure> list) {
    chatList = list;
    notifyListeners();
  }

  // 添加聊天好友列表
  void addChatList(ChatListStructure value) {
    
    chatList.add(value);
    notifyListeners();

    // print('添加了一条聊天好友数据：$value');
  }
  void updateChatListData(int index, ChatListStructure data) {
    chatList[index] = data;
    notifyListeners();
  }
  // 通过id更新聊天列表
  void updateChatListByChatTable(String chatTable, ChatListStructure data) {
    for (var i = 0; i < chatList.length; i++) {
      if (chatList[i].chat_table == chatTable) {
        chatList[i] = data;
        notifyListeners();
        break;
      }
    }
  }
  // 通过id获取聊天列表
  ChatListStructure? getChatListByChatTable(String chatTable) {
    for (var i = 0; i < chatList.length; i++) {
      if (chatList[i].chat_table == chatTable) {
        return chatList[i];
      }
    }
    return null;
  }

  // 设置登陆状态
  void setConnecteStatus(String status) {
    connecteStatus = status;
    notifyListeners();
  }

  // 新增头像映射
  void addAvatarMap(String key, String value) {
    avatarMap[key] = value;
    notifyListeners();
  }

  // 清空头像映射
  void clearAvatarMap() {
    avatarMap.clear();
    notifyListeners();
  }
  // 删除头像映射
  void deleteAvatarMap(String key) {
    avatarMap.remove(key);
    notifyListeners();
  }

  // 获取头像映射
  String getAvatarMap(String key) {
    return avatarMap[key] ?? '';
  }

  setUserInfo(UserInfo userinfo) {
    userInfo = userinfo;
    notifyListeners();
  }

  // 新增总未读消息数
  void addTotalUnread(int value) {
    totalUnread += value;
    notifyListeners();
  }

  // 清空总未读消息数
  void clearTotalUnread() {
    totalUnread = 0;
    notifyListeners();
  }

  // 减少总未读消息数
  void reduceTotalUnread(int value) {
    totalUnread -= value;
    notifyListeners();
  }

  // 设置图片映射
  void setAvatarFileMap(String key, Uint8List? value) {
    avatarFileMap[key] = value;
    notifyListeners();
  }

  // 获取图片映射
  Uint8List? getAvatarFileMap(String key) {
    return avatarFileMap[key];
  }

  // 清空图片映射
  void clearAvatarFileMap() {
    avatarFileMap.clear();
    notifyListeners();
  }

  // 通过chat_table删除文件映射
  void deleteAvatarFileMapByChatTable(String chatTable) {
    avatarFileMap.removeWhere((key, value) {
      // print('key: $key, chatTable: $chatTable, contains: ${!key.contains(chatTable)}');
      return !key.contains(chatTable);
    });
    // print('avatarFileMap: ${avatarFileMap.length}');
    // notifyListeners();
  }

}

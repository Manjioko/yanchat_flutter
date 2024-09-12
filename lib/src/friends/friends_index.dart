import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:yanchat01/src/avatar/avatar_index.dart';
import 'package:yanchat01/src/chat/chat_index.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/image_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:yanchat01/src/util/request.dart';
// import 'package:yanchat01/src/util/share.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});
  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  final List<FriendsListStructure> friends = [];
  Directory? appDocDir;
  

  @override
  void initState() {
    super.initState();
    _getFriends();
  }

  // Future<String> _setAvatar(FriendsListStructure friendData) async {
  //   final baseUrl = await Share.instance.getString('baseUrl') ?? '';
  //   // print("好友下载头像");
  //   final boxhcatData = Provider.of<BoxDataNotifier>(context, listen: false);
  //   var userInfo = boxhcatData.userInfo;
  //   // 有时候boxchatData并不可靠，在极端条件下或者调试时,在内存中的数据可能会丢失
  //   // 所以防止出现丢失时无法处理数据的情况，需要从数据库中重新加载数据
  //   if (userInfo == null) {
  //     final userinfoList = await queryUserInfo(null);
  //     if (userinfoList.isNotEmpty) {
  //       userInfo = UserInfo.fromDbJsonList(userinfoList)[0];
  //     }
  //   }
  //   // 用户自己的头像
  //   final selfPath = path.join(appDocDir!.path, 'avatar_${boxhcatData.userInfo?.userId ?? ''}.jpg');
  //   final selfFile = File(selfPath);
  //   if (selfFile.existsSync()) {
  //     boxhcatData.addAvatarMap(userInfo?.userId ?? '', selfPath);
  //   } else {
      
  //     Request.instance.dio.download("$baseUrl/avatar/avatar_${boxhcatData.userInfo?.userId ?? ''}.jpg", selfPath)
  //     .catchError((e) {
  //       print('下载自己头像失败：$e');
  //       boxhcatData.addAvatarMap(userInfo?.userId ?? '', 'images/default_avatar.png');
  //       return e;
  //     });
  //   }
  //   if (friendData.avatar_url == null) {
  //     final filePath =
  //         path.join(appDocDir!.path, 'avatar_${friendData.user_id}.jpg');

  //     final file = File(filePath);
  //     // 下载图片
  //     if (file.existsSync()) {
  //       // print("本地头像存在");
  //       boxhcatData.addAvatarMap(friendData.user_id, filePath);
  //       return filePath;
  //     }
  //     if (friendData.ai == true) {
  //       Request.instance.dio.download("$baseUrl/avatar/avatar_default.png", filePath)
  //         .catchError((e) {
  //           print('下载默认头像失败:$e');
  //           return e;
  //         });
  //     } else {
  //       Request.instance.dio.download("$baseUrl/avatar/avatar_${friendData.user_id}.jpg",filePath)
  //         .catchError((e) {
  //           print('下载默认头像失败:$e');
  //           return e;
  //         });
  //     }
  //     friendData.avatar_url = filePath;
  //     boxhcatData.addAvatarMap(friendData.user_id, filePath);
  //     // print("下载头像成功");
  //     return filePath;
  //   } else {
  //     // 本地图片
  //     // print("本地头像存在 ${friendData.avatar_url}");
  //     final avatarPath = path.join(appDocDir!.path, friendData.avatar_url!);
  //     boxhcatData.addAvatarMap(friendData.user_id, avatarPath);
  //     // print("本地头像成功");
  //     return friendData.avatar_url!;
  //   }
  // }

  void _getFriends() async {
    appDocDir = await getApplicationDocumentsDirectory();
    // 查数据库获取好友信息
    if (friends.isNotEmpty) {
      for (var f in friends) {
        // _setAvatar(f);
        setAvatar(f.user_id, context);
      }
      return;
    }

    // 查数据库获取好友信息
    final List<Map<String, dynamic>> maps = await queryFriendsList(null);
    for (var e in maps) {
      final data = FriendsListStructure.fromJson(e);
      setAvatar(data.user_id, context);
      // data.avatar_url = avatar;
      setState(() {
        friends.add(data);
      });
    }
  }

  // 点击后把数据更新到 chatList
  void _insertChatList(FriendsListStructure friendsListStructure) async {
    // 查询聊天好友数据
    final phoneNumber = friendsListStructure.phone_number;
    final isExist = await queryChatList(phoneNumber);
    final boxChatNotifier =
        Provider.of<BoxDataNotifier>(context, listen: false);

    setData() async {
      final chatListStructure = ChatListStructure(
          user_id: friendsListStructure.user_id,
          user: friendsListStructure.user,
          phone_number: friendsListStructure.phone_number,
          db_version: friendsListStructure.db_version,
          avatar_url: friendsListStructure.avatar_url,
          is_use_md: friendsListStructure.is_use_md,
          created_at: friendsListStructure.created_at,
          updated_at: friendsListStructure.updated_at,
          chat_table: friendsListStructure.chat_table,
          chat: '',
          time: '',
          unread: 0,
          read: 0,
          silent: 0);
      await insertChatList(chatListStructure);
      boxChatNotifier.addChatList(chatListStructure);
    }

    if (phoneNumber == null && friendsListStructure.ai == true) {
      if (!boxChatNotifier.chatList
          .any((e) => e.user_id == friendsListStructure.user_id)) {
        // 插入聊天好友数据
        setData();
        return;
      }
    }

    if (isExist.isEmpty) {
      // 插入聊天好友数据
      setData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BoxDataNotifier>(
        builder: (context, BoxDataNotifier boxChatNotifier, child) {
      return ListView.builder(
        padding: const EdgeInsets.all(0.0),
        itemCount: friends.length,
        // itemExtent: 80.0,
        itemBuilder: (context, index) {
          return Column(children: <Widget>[
            Container(
              color: Colors.white,
              height: 75.0,
              child: Center(
                child: ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Avatar(width: 50.0, height: 50.0, userId: friends[index].user_id),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(friends[index].user, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),)],
                  ),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      _insertChatList(friends[index]);
                      return ChatPage(friend: friends[index]);
                    }));
                  },
                ),
              ),
            ),
            Divider(
              height: 0.5,
              color: Colors.grey[200],
              indent: 50.0,
              endIndent: 0.0,
            )
          ]);
        },
      );
    });
  }
}

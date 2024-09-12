import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/avatar/avatar_index.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/index.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/scheduler.dart';
import 'package:yanchat01/src/record/audio_player.dart';
import 'package:yanchat01/src/util/box_notifier.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/image/image_index.dart';
import 'package:yanchat01/src/util/share.dart';
import 'package:yanchat01/src/video/video_index.dart';
import 'package:yanchat01/src/record/record_index.dart';
import 'package:yanchat01/src/chatText/chat_text_index.dart';
import 'package:yanchat01/src/chatInput/chat_input_index.dart';
import 'package:yanchat01/src/tray/tray_index.dart';
import 'package:yanchat01/src/file/file_index.dart';

var uuid = const Uuid();

class ChatPage extends StatefulWidget {
  final FriendsListStructure friend;

  const ChatPage({
    super.key,
    required this.friend,
  });

  @override
  State<ChatPage> createState() => _FriState();
}

class _FriState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _showTray = false;
  double bottomInset = 0.0;
  double keyBoardHeight = 0.0;
  String selfAvatarPath = 'images/default_avatar.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // _clearOldFileMap();
    _clearOldFileMap();
    hidenKeyBoard();
    _handleDB();
    _handleUnread();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    handleActive('');
    // 把播放器的资源释放掉
    AudioPlayerManager.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bottomInset = MediaQuery.of(context).viewInsets.bottom;
      if (bottomInset > 0.0) {
        // print("bottomInset: $bottomInset");
        _scrollToBottom();
        keyBoardHeight = bottomInset;
      } else {
        // print("bottomInset: $bottomInset");
      }
    });
  }

  void _scrollToBottom() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // _scrollController.position.maxScrollExtent
        _scrollController.jumpTo(0.0);
      }
    });
  }

  // 页面激活
  void handleActive(String activeId) async {
    Share.instance.setString('activeId', activeId);
  }

  // 清空不属于当前用户的文件
  void _clearOldFileMap() {
    final boxNotifier = BoxNotifier.instance.box(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      boxNotifier.deleteAvatarFileMapByChatTable(widget.friend.chat_table);
    });
  }

  // 收起键盘
  void hidenKeyBoard() {
    // 在页面加载时收起键盘
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // print("收起键盘");
      FocusScope.of(context).unfocus();
    });
  }

  void _toggleTray(bool? value) {
    setState(() {
      if (value == null) {
        _showTray = !_showTray;
      } else {
        _showTray = value;
      }
    });
  }

  void _handleDB() async {
    final userId = await Share.instance.getString('userId') ?? '';
    if (userId.isNotEmpty) {
      final appDocDir = await getApplicationDocumentsDirectory();
      setState(() {
        selfAvatarPath = path.join(appDocDir.path, 'avatar_$userId.jpg');
      });
    }
    final boxNotifier = BoxNotifier.instance.box(context);
    final tablename = widget.friend.chat_table;
    final isExistList = await queryChatTable(tablename, null);

    // 设置 active
    handleActive(widget.friend.chat_table);

    if (isExistList.isEmpty) {
      boxNotifier.setBoxList([]);
      await createChatTable(tablename);
    } else {
      boxNotifier.setBoxList([]);
      for (var e in isExistList) {
        boxNotifier.addBoxList(ChatBox.fromJson(e), isFirst: true);
      }
      _scrollToBottom();
    }
  }

  void _handleUnread() async {
    final boxNotifier = BoxNotifier.instance.box(context);
    for (var i = 0; i < boxNotifier.chatList.length; i++) {
      final chatlist = boxNotifier.chatList[i];
      if (chatlist.chat_table == widget.friend.chat_table) {
        if (chatlist.unread != null && chatlist.unread! > 0) {
          int unread = chatlist.unread ?? 0;

          // 将未读数量清零
          chatlist.unread = 0;
          await updateChatList(chatlist);
          boxNotifier.updateChatListData(i, chatlist);
          // 这步是在未读清空前，将总未读数量减去已读未读数量
          boxNotifier.reduceTotalUnread(unread);
          break;
        }
      }
    }
  }

  Widget returnMessageData(ChatBox chat) {
    if (chat.type == 'text') {
      return ChatText(chatBox: chat);
    } else if (chat.type?.contains('audio') ?? false) {
      // 音频
      return PlayerAudio(
        chatBox: chat,
        friend: widget.friend,
      );
    } else if (chat.type?.contains('video') ?? false) {
      // 视频
      return ShowVideoThumbnail(chatBox: chat, key: ValueKey(chat.localFileName));
    } else if (chat.type?.contains('image') ?? false) {
      return ShowThumbnail(chatBox: chat, key: ValueKey(chat.localFileName));
    } else {
      chat.type = 'file';
      // 文件
      return FileBox(chatBox: chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.user),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 16.0),
        backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: GestureDetector(
        onTap: () => hidenKeyBoard(),
        child: Column(
          children: [
            Expanded(
                // provider 通信 双向绑定数据
                child: Align(
              alignment: Alignment.topCenter,
              child: Selector<BoxDataNotifier, int>(
                selector: (context, boxDataNotifier) => boxDataNotifier.boxList.length,
                builder: (context, boxLength, child) {
                  final boxList = BoxNotifier.instance.box(context).boxList;
                  return MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    // ListView 是滚动页面的容器，是整个页面的核心部分
                    child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      controller: _scrollController,
                      itemCount: boxLength,
                      itemBuilder: (context, index) {
                        return Align(
                          key: ValueKey(boxList[index].chat_id),
                          alignment: boxList[index].user == 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start, // 添加这一行
                            children: [
                              if (boxList[index].user == 1)
                                Align(
                                  alignment: Alignment.topLeft, // 固定头像在顶部
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        left: 16, top: 16),
                                    child: Avatar(
                                        width: 45,
                                        height: 45,
                                        userId: boxList[index].to_id
                                      ),
                                  ),
                                ),
                              returnMessageData(boxList[index]),
                              if (boxList[index].user == 0)
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Avatar(
                                      width: 45,
                                      height: 45,
                                      userId: boxList[index].to_id),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )),
            ChatInput(
              scrollController: _scrollController,
              onToggleTray: _toggleTray,
              friendData: widget.friend,
              scrollToBottom: _scrollToBottom,
            ),
            if (_showTray)
              Tray(
                onToggleTray: _toggleTray,
                scrollToBottom: _scrollToBottom,
                friend: widget.friend,
              )
          ],
        ),
      ),
    );
  }
}

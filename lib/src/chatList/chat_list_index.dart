import 'package:flutter/material.dart';
import 'package:yanchat01/src/avatar/avatar_index.dart';
import 'package:yanchat01/src/chat/chat_index.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:yanchat01/src/index.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/util/global_type.dart';


class ChatList extends StatefulWidget {
  const ChatList({super.key});
  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final List<ChatListStructure> boxList = [];
  // dynamic appDocDir;

  @override
  void initState() {
    super.initState();
    _initChatListData();
  }

  void _initChatListData() async {
    final boxChatNotifier = Provider.of<BoxDataNotifier>(context, listen: false);
    final getChatListByDB = await queryChatList(null);
    boxChatNotifier.setChatList([]);
    // appDocDir = await getApplicationDocumentsDirectory();
    for (var e in getChatListByDB) {
      final chatlist = ChatListStructure.fromJson(e);

      // 看下头像设置了没
      boxChatNotifier.addChatList(chatlist);
    }
  }

  String handleTime(String time) {
    if (time.isNotEmpty) {
      return time.split(' ')[1];
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BoxDataNotifier>(builder: (context, BoxDataNotifier boxChatNotifier, child) {
      return ListView.builder(
        padding: const EdgeInsets.all(0.0),
        itemCount: boxChatNotifier.chatList.length,
        // itemExtent: 80.0,
        itemBuilder: (context, index) {
          return Column(children: <Widget>[
            Slidable(
                // Specify a key if the Slidable is dismissible.
                key: ValueKey(index),

                // The start action pane is the one at the left or the top side.
                endActionPane: ActionPane(
                  // A motion is a widget used to control how the pane animates.
                  motion: const ScrollMotion(),

                  // A pane can dismiss the Slidable.
                  dismissible: DismissiblePane(onDismissed: () {}),

                  // All actions are defined in the children parameter.
                  children: [
                    // A SlidableAction can have an icon and/or a label.
                    SlidableAction(
                      onPressed: (BuildContext context) {},
                      backgroundColor: const Color(0xFF21B7CA),
                      foregroundColor: Colors.white,
                      icon: Icons.push_pin_outlined,
                      label: '置顶',
                    ),
                    SlidableAction(
                      // flex: 2,
                      onPressed: (BuildContext context) {},
                      backgroundColor: const Color(0xFFFE4A49),
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: '删除',
                    ),
                  ],
                ),
                child: Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: Stack(
                      fit: StackFit.passthrough,
                      clipBehavior: Clip.none,
                      children: [
                        // boxChatNotifier.avatarMap[boxChatNotifier.chatList[index].user_id] ?? 'images/default_avatar.png'
                        Avatar(width: 50.0, height: 50.0, userId: boxChatNotifier.chatList[index].user_id),
                        if (boxChatNotifier.chatList[index].unread! > 0)
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              boxChatNotifier.chatList[index].unread.toString(),
                              // '1',
                              style: const TextStyle(
                                  fontSize: 14.0, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )

                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          boxChatNotifier.chatList[index].user,
                            style: const TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold
                            )
                          ),
                        Text(
                          handleTime(boxChatNotifier.chatList[index].time  ?? ''),
                          style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                        ),
                      ],  
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ChatPage(friend: boxChatNotifier.chatList[index]);
                      }));
                    },
                    subtitle: Text(
                      boxChatNotifier.chatList[index].chat ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
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

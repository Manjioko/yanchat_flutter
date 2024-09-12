import 'package:flutter/material.dart';
// import 'package:uuid/uuid.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/record/record_index.dart';
import 'dart:async';

import 'package:yanchat01/src/util/uuid.dart';


// var uuid = const Uuid();

class ChatInput extends StatefulWidget {
  final ScrollController scrollController;
  final Function(bool?) onToggleTray;
  final FriendsListStructure friendData;
  final Function() scrollToBottom;

  const ChatInput(
      {super.key,
      required this.scrollController,
      required this.onToggleTray,
      required this.friendData,
      required this.scrollToBottom});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool keyBoardIsShow = false;
  String userId = '';
  bool isRecord = false; // 录音状态
  // bool _isTrayVisible = false;

  @override
  void initState() {
    super.initState();
    getUserId();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // print('键盘打开');
      setState(() {
        keyBoardIsShow = true;
        widget.onToggleTray(false);
        // 如果托盘显示，隐藏它
      });
      // _scrollToBottom();
    } else {
      // print('键盘关闭');
      setState(() {
        keyBoardIsShow = false;
      });

      // _scrollToBottom();
    }
  }

  void getUserId() async {
    if (userId.isEmpty) {
      final userData = await queryUserInfo(null);
      userId = userData[0]['userId'];
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty) {
      getUserId();
      final boxDataNotifier =
          Provider.of<BoxDataNotifier>(context, listen: false);
      // ChatBox map =
      ChatBox chatBox = ChatBox.fromJson({
        'type': 'text',
        'text': _controller.text.trim(),
        'user': 0,
        'time': formatDate(DateTime.now(),
            [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]),
        'chat_id': Uid.instance.v4,
        'quote': '',
        'to_table': widget.friendData.chat_table,
        'to_id': widget.friendData.user_id,
        'user_id': userId,
        'loading': false
      });
      boxDataNotifier.addBoxList(chatBox, isFirst: true);
      boxDataNotifier.ws?.add(jsonEncode(chatBox.toJson()));
      // 插入数据库中
      insertChatTable(widget.friendData.chat_table, chatBox);
      for (int index = 0; index < boxDataNotifier.boxList.length; index++) {
        final e = boxDataNotifier.chatList[index];
        if (e.user_id == widget.friendData.user_id) {
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
      // 更新到聊天列表 数据库
      _controller.clear();
      FocusScope.of(context).requestFocus(_focusNode); // 保持焦点
      widget.scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: const Color.fromARGB(255, 236, 236, 236),
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: keyBoardIsShow && !isRecord ? 8.0 : 38.0,
        left: 8.0,
        right: 8.0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.record_voice_over_outlined,
                size: 30, color: isRecord ?
                Colors.blueAccent.withOpacity(0.5) : 
                const Color.fromARGB(255, 102, 102, 102)),
            onPressed: () {
              setState(() {
                isRecord = !isRecord;
              });
            },
          ),
          const SizedBox(width: 8),
          if (isRecord)
          RecordAudio(friend: widget.friendData)
          else
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(),
              decoration: InputDecoration(
                hintText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    width: 0,
                    style: BorderStyle.none,
                  ),
                ),
              ),
              minLines: 1,
              maxLines: 5, // 设置最小和最大行数
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                size: 30, color: Color.fromARGB(255, 102, 102, 102)),
            onPressed: () {
              FocusScope.of(context).unfocus();
              Timer(const Duration(milliseconds: 100), () {
                widget.onToggleTray(null);
              });
              // widget.onToggleTray(null);
            },
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
import 'package:yanchat01/src/util/global_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:yanchat01/src/popUp/pop_up_index.dart';

class ChatText extends StatefulWidget {
  final ChatBox chatBox;

  const ChatText({
    super.key,
    required this.chatBox,
  });

  @override
  State<ChatText> createState() => _ChatTextState();
}

class _ChatTextState extends State<ChatText> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: PopUp(
      chatBox: widget.chatBox,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.chatBox.user == 0 ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextSelectionTheme(
          data: TextSelectionThemeData(
            cursorColor: Colors.blue,
            selectionColor: widget.chatBox.user == 0
                ? Colors.greenAccent.withOpacity(0.5)
                : Colors.blueAccent.withOpacity(0.5),
            // selectionHandleColor: Colors.blue,
          ),
          child: Theme(
            data: ThemeData(
                cupertinoOverrideTheme:
                    const CupertinoThemeData(primaryColor: Colors.green)),
            child: SelectableText(
              widget.chatBox.text,
              style: TextStyle(
                color: widget.chatBox.user == 0 ? Colors.white : Colors.black,
                fontSize: 16.0,
              ),
              // softWrap: true, // 允许自动换行
            ),
          ),
        ),
      ),
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/popUp/pop_up_index.dart';

class FileBox extends StatefulWidget {
  final ChatBox chatBox;
  const FileBox({
    super.key,
    required this.chatBox,
  });

  @override
  State<FileBox> createState() => _FileBoxState();
}

class _FileBoxState extends State<FileBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: PopUp(
        chatBox: widget.chatBox,
        child: GestureDetector(
            onTap: () async {},
            child: Container(
              height: 100,
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(235,243,254,1.000),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  // const SizedBox(width: 16),
                  Flexible(
                      fit: FlexFit.tight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatBox.fileName ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.chatBox.size ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      )),
                  Image.asset('images/uploadedFile.png', width: 55),
                  // const SizedBox(width: 16),
                ],
              ),
            )),
      ),
    );
  }
}

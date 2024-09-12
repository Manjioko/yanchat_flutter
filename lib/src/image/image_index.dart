// import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yanchat01/src/util/box_notifier.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/image_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:yanchat01/src/popUp/pop_up_index.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/index.dart';
import 'package:flutter/services.dart' show rootBundle;

class ShowThumbnail extends StatefulWidget {
  final ChatBox chatBox;

  const ShowThumbnail({
    super.key,
    required this.chatBox,
  });

  @override
  State<ShowThumbnail> createState() => _ShowThumbnailState();
}

class _ShowThumbnailState extends State<ShowThumbnail>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // Uint8List? cachedImage;
  Uint8List? imageLoadedData;
  bool failToLoad = false;

  @override
  void initState() {
    super.initState();
    print('initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThumbnail();
    });
  }

  @override
  void didUpdateWidget(covariant ShowThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检查userId或name是否发生变化
    if (oldWidget.chatBox.user_id != widget.chatBox.user_id ||
        oldWidget.chatBox.localFileName != widget.chatBox.localFileName) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() async {
    print('loadThumbnail');
    final boxChatData = Provider.of<BoxDataNotifier>(context, listen: false);
    final type = widget.chatBox.type;
    final fileMapName =
        '${widget.chatBox.to_table}_${type}_${widget.chatBox.localFileName}';
    final cache = boxChatData.getAvatarFileMap(fileMapName);

    if (cache != null) {
      return;
    }

    try {
      final img = await getThumbnail(widget.chatBox);
      boxChatData.setAvatarFileMap(fileMapName, img);
    } catch (e) {
      // print('getThumbnail error: $e');
      final dataByte = await rootBundle.load('images/failToLoad.png');
      final img = dataByte.buffer.asUint8List();
      boxChatData.setAvatarFileMap(fileMapName, img);
      setState(() {
        failToLoad = true;
      });
    }
  }

  Widget buildImageFromData(Uint8List imageData) {
    return Container(
      key: Key(widget.chatBox.chat_id),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: PopUp(
        chatBox: widget.chatBox,
        child: GestureDetector(
          key: Key(widget.chatBox.chat_id),
          onTap: () {
            _showFullImage(imageData);
          },
          // child: Image.file(),
          child: Image.memory(imageData,
              fit: BoxFit.contain,
              width: failToLoad ? 100 : 180,
              gaplessPlayback: true,
              excludeFromSemantics: true),
        ),
      ),
    );
  }

  void _showFullImage(Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
                backgroundColor: Colors.black, // 设置背景色为黑色
                insetPadding: EdgeInsets.zero, // 确保图片全屏
                child: GestureDetector(
                  // behavior: HitTestBehavior.opaque, // 让手势检测传递到整个区域
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! > 20) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: PhotoView(
                    imageProvider: widget.chatBox.user == 0
                        ? MemoryImage(imageData)
                        : NetworkImage(widget.chatBox.src ?? ''),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black, // 背景透明
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4.0, // 调整缩放比例
                    // enableRotation: true,
                    onTapUp: (context, details, controller) {
                      Navigator.of(context).pop();
                    },
                  ),
                ));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final type = widget.chatBox.type;
    final fileMapName =
        '${widget.chatBox.to_table}_${type}_${widget.chatBox.localFileName}';
    final boxNotifier = BoxNotifier.instance.box(context);
    final cache = boxNotifier.getAvatarFileMap(fileMapName);
    return cache != null
        ? buildImageFromData(cache)
        : const CircularProgressIndicator();
  }
}

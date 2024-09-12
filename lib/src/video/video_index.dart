import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:yanchat01/src/popUp/pop_up_index.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/video_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/index.dart';

class ShowVideoThumbnail extends StatefulWidget {
  final ChatBox chatBox;

  const ShowVideoThumbnail({
    super.key,
    required this.chatBox,
  });

  @override
  State<ShowVideoThumbnail> createState() => _ShowVideoThumbnailState();
}

class _ShowVideoThumbnailState extends State<ShowVideoThumbnail>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // Uint8List? cachedImage;
  late VideoPlayerController _controller;
  // bool _isInitialized = false;
  bool _isPlaying = false;
  String videoDuration = '00:00';
  dynamic statusSet;
  bool isInit = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThumbnail();
    });
  }

  @override
  void dispose() {
    try {
      _controller.removeListener(_updateUI); // 清理监听器
      _controller.dispose();
    } catch (e) {
      // _controller 在dispose时可能还没有被初始化
      // print(e);
    }
    super.dispose();
  }

  // 更新UI
  void _updateUI() {
    if (mounted) {
      String time = _formatDuration(_controller.value.position);
      setState(() {
        _isPlaying = _controller.value.isPlaying;
        videoDuration = time;
        if (statusSet != null) {
          statusSet(() {
            isInit = true;
          });
        }
      });
    }
  }

  // 播放暂停
  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  // 计算视频时长
  String _formatDuration(Duration position) {
    // print("position: $position");
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(position.inHours);
    final minutes = twoDigits(position.inMinutes.remainder(60));
    final seconds = twoDigits(position.inSeconds.remainder(60));
    return [if (position.inHours > 0) hours, minutes, seconds].join(":");
  }

  @override
  void didUpdateWidget(covariant ShowVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatBox.user_id != widget.chatBox.user_id ||
        oldWidget.chatBox.localFileName != widget.chatBox.localFileName) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() async {
    final boxChatData = Provider.of<BoxDataNotifier>(context, listen: false);
    final type = widget.chatBox.type;
    final fileMapName =
        '${widget.chatBox.to_table}_${type}_${widget.chatBox.localFileName}';
    final cache = boxChatData.getAvatarFileMap(fileMapName);

    if (cache != null) {
      return;
    }

    getVideoThumbnail(widget.chatBox).then((img) {
      boxChatData.setAvatarFileMap(fileMapName, img);
    });
  }

  Widget buildVideoThumbnailFromData(Uint8List imageData) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      // padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: PopUp(
        chatBox: widget.chatBox,
        child: GestureDetector(
          onTap: () async {
            _showFullVideo(imageData);
            final video = await getVideo(widget.chatBox);
            if (video != null) {
              _controller = (widget.chatBox.user == 0
                  ? VideoPlayerController.file(video)
                  : VideoPlayerController.networkUrl(
                      Uri.parse(widget.chatBox.src ?? '')))
                ..initialize().then((_) {
                  // print('初始化完成');
                  _controller.addListener(_updateUI);
                  setState(() {
                    // _isInitialized = true;
                    statusSet(() {
                      isInit = true;
                    });
                  });
                });
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.memory(imageData,
                  fit: BoxFit.contain,
                  width: 180,
                  gaplessPlayback: true,
                  excludeFromSemantics: true),
              if (!_isPlaying)
                const Icon(
                  Icons.play_circle_fill_sharp,
                  color: Color.fromARGB(221, 255, 255, 255),
                  size: 40,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullVideo(Uint8List imageData) async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            setState(() {
              // _togglePlayPause();
              statusSet = setState;
            });
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.zero,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 20) {
                    _controller.pause();
                    Navigator.of(context).pop();
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _togglePlayPause();
                        });
                      },
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            isInit
                                ? AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: VideoPlayer(_controller),
                                  )
                                : const CircularProgressIndicator(),
                            if (!_isPlaying)
                              const Icon(Icons.play_arrow,
                                  size: 64.0, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20.0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _togglePlayPause();
                              });
                            },
                          ),
                          Expanded(
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.red,
                                backgroundColor: Colors.grey,
                                bufferedColor: Colors.white54,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8.0, right: 8.0),
                            child: Text(
                              videoDuration,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, BoxDataNotifier boxChatData, child) {
        final type = widget.chatBox.type;
        final fileMapName =
            '${widget.chatBox.to_table}_${type}_${widget.chatBox.localFileName}';
        final cache = boxChatData.getAvatarFileMap(fileMapName);
        return cache != null
            ? buildVideoThumbnailFromData(cache)
            : const CircularProgressIndicator();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanchat01/src/util/doc_path.dart';
import 'dart:io';
import 'dart:convert';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yanchat01/src/index.dart';
import 'package:date_format/date_format.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/util/upload.dart';
import 'package:just_audio/just_audio.dart';
import 'package:yanchat01/src/popUp/pop_up_index.dart';
import 'package:yanchat01/src/util/uuid.dart';
import 'package:yanchat01/src/util/video_handler.dart';
import './audio_player.dart';

class RecordAudio extends StatefulWidget {
  final FriendsListStructure friend;
  const RecordAudio({super.key, required this.friend});

  @override
  State<RecordAudio> createState() => _RecordAudioState();
}

class _RecordAudioState extends State<RecordAudio> {
  bool isTapDown = false;
  late AudioRecorder record;
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    record = AudioRecorder();
    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    record.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void startRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final toTable = prefs.getString('activeId');
    if (toTable == null) {
      print('没有聊天对象');
      return;
    }
    final uid = Uid.instance.v4;
    final appDocDir = await getApplicationDocumentsDirectory();
    final path = '${appDocDir.path}/$userId/$toTable/Records';

    if (!await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }

    // 检查是否有录音权限
    if (await record.hasPermission()) {
      // Start recording to file
      await record.start(const RecordConfig(), path: '$path/${uid}_record.m4a');
    } else {
      print('没有录音权限');
    }
  }

  void stopRecord() async {
    final path = await record.stop();
    if (path == null) {
      return;
    }
    _sendRecord(path.split('/').last);
    print('停止录音:${path.split("/").last}');
  }

  void cacelRecord() async {
    await record.cancel();
    print('取消录音!!!');
  }

  Future<int> getRecordDuration(ChatBox chatBox) async {
    try {
      final audioPath = await getAudioPath(chatBox);
      print('音频文件路径：$audioPath');
      // 加载音频文件
      await audioPlayer.setFilePath(audioPath!);

      // 获取音频文件的时长
      final duration = audioPlayer.duration;

      return duration!.inSeconds.toInt();
    } catch (e) {
      print("Error loading audio: $e");
      return 0;
    }
  }


  void _sendRecord(String recordPath) async {
    print('发送录音:$recordPath');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    // final toTable = prefs.getString('activeId');
    final boxDataNotifier =
        Provider.of<BoxDataNotifier>(context, listen: false);
    ChatBox chatBox = ChatBox.fromJson({
      'type': 'audio/mp3',
      'text': '[语音]', 
      'user': 0,
      'time': formatDate(
          DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]),
      'chat_id': Uid.instance.v4,
      'quote': '',
      'to_table': widget.friend.chat_table,
      'to_id': widget.friend.user_id,
      'user_id': userId ?? '',
      'loading': false,
      'src': '',
      'thumbnail': '',
      'destroy': false,
      'fileName': recordPath,
      'localFileName': recordPath,
      'progress': 0,
      'audioDuration': 0,
    });
    final duration = await getRecordDuration(chatBox);
    chatBox.audioDuration = duration;
    chatBox.user_id = userId ?? '';

    print('userid是:$userId');
    
    // if (userId != null) return;

    print('userid存在，发送到服务器');


    boxDataNotifier.addBoxList(chatBox, isFirst: true);
    // 插入数据库中
    insertChatTable(widget.friend.chat_table, chatBox);

    // 上传到服务器
    final audioPath = await getAudioPath(chatBox);
    mediaUpload(File(audioPath!), (String? err, int? percent, String? localFileName) {
      if (localFileName != null) {
        // print('上传成功，文件名称是 $localFileName');
        final baseUrl = prefs.getString('baseUrl') ?? '';
        chatBox.response = localFileName;
        chatBox.src = '$baseUrl/source/$localFileName';
        chatBox.progress = 100;
        boxDataNotifier.updateBoxListByChatId(chatBox);
        boxDataNotifier.ws?.add(jsonEncode(chatBox.toJson()));

        // 上传成功提示
        // final uploadSuccessTips = {
        //     'to_id': widget.friend.user_id,
        //     'user_id': userId,
        //     'to_table': widget.friend.chat_table,
        //     'messages_type': 'uploadSuccess',
        //     'messages_box': {
        //         'uploadState': 'success',
        //         'progress': 100,
        //         'response': chatBox.response,
        //         'chat_id': chatBox.chat_id,
        //         'src': '$baseUrl/source/$localFileName',
        //         'to_table': chatBox.to_table,
        //     }
        // };
        // boxDataNotifier.ws?.add(jsonEncode(uploadSuccessTips));
        // print('上传成功提示：$uploadSuccessTips');
        return;
      }
      if (percent != null) {
        print('上传进度 $percent');
        // final eventParam = {
        //     'event': 'progress',
        //     'data': {
        //         'chat_id': chatBox.chat_id,
        //         'progress': percent
        //     },
        //     'to_id': chatBox.to_id,
        //     'to_table': chatBox.to_table,
        //     'user_id': chatBox.user_id
        // };
        // boxDataNotifier.ws?.add(jsonEncode(eventParam));
        return;
      }
      if (err != null) {
        print('上传失败: $err');
        return;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            isTapDown = true;
          });
          startRecord();
        },
        onTapUp: (_) {
          setState(() {
            isTapDown = false;
          });
          stopRecord();
        },
        onTapCancel: () {
          setState(() {
            isTapDown = false;
          });
          cacelRecord();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isTapDown ? Colors.green[200] : Colors.white,
          ),
          padding: const EdgeInsets.all(12.5),
          width: double.infinity,
          // height: double.infinity,
          // color: Colors.white,
          child: Text(
            isTapDown ? '松开 发送' : '按住 说话',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isTapDown ?
              Colors.white :
              Colors.black)
            ),
        ),
      ),
    );
  }
}


class PlayerAudio extends StatefulWidget {
  // final String recordPath;
  final ChatBox chatBox;
  final FriendsListStructure friend;
  const PlayerAudio({ super.key, required this.chatBox, required this.friend });
  @override
  State<PlayerAudio> createState() => _PlayerAudioState();
}

class _PlayerAudioState extends State<PlayerAudio> {

  // 播放语音的构造函数应该放在 home_index.dart 中
  // 因为如果每条语音都需要构造一条，会影响性能

  @override
  void initState() {
    final isPlayDispose = AudioPlayerManager.instance.isDispose;
    if (isPlayDispose) {
      AudioPlayerManager.instance.reCreate();
    }
    super.initState();
  }

  void playAudio(ChatBox chatBox) async {
    final audioInstace = AudioPlayerManager.instance;
    final audioPlayer = AudioPlayerManager.instance.player;
    try {
      String apth = '';
      bool islocalAudio = false;
      // if (chatBox.user == 0) {
      //   // 本地语音
      //   final localPath = await getAudioPath(chatBox);
      //   apth = localPath!;
      //   islocalAudio = true;
      // } else {
      //   // 远程语音
      //   final remotePath = chatBox.src;
      //   apth = remotePath!;
      //   islocalAudio = false;
      // }

      if (chatBox.user != 0) {
        final lcoalPath = await getAudioPath(chatBox);
        final isExistLocalAudio = await DocPath.fileIsExists(lcoalPath ?? '');
        if (isExistLocalAudio) {
          apth = lcoalPath!;
          print("用本地语音： $apth");
          islocalAudio = true;
        } else {
          final remotePath = chatBox.src;
          apth = remotePath!;
          islocalAudio = false;
        }
      }


      if (audioPlayer.playing) {
        await audioPlayer.stop();
        // 如果用户点的不是同一段音频，就暂停播放当前的音频
        // 转而播放其他的音频，如果用户点的是同一段音频，就直接不再播放任何音频
        if (audioInstace.chatId == chatBox.chat_id) {
          return;
        }
      }
      // audioInstace.audioPath = apth;
      audioInstace.chatId = chatBox.chat_id;
      if (islocalAudio) {
        await audioPlayer.setFilePath(apth);
      } else {
        await audioPlayer.setUrl(apth);
      }
      await audioPlayer.play();
    } catch (e) {
      // final remotePath = chatBox.src;
      print("Error playing audio: $e");
    }
  }

  void stopAudio() async {
    final audioPlayer = AudioPlayerManager.instance.player;
    await audioPlayer.stop();
  }
  @override
  Widget build(BuildContext context) {
    final text = widget.chatBox.user == 0 ? "${widget.chatBox.audioDuration}'' 语音" : "语音 ${widget.chatBox.audioDuration}''";
    return Flexible(
          child: PopUp(
        chatBox: widget.chatBox,
        child: StreamBuilder(
          stream: AudioPlayerManager.instance.player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing ?? false;

            getColor() {
              if (!playing || processingState == ProcessingState.completed) {
                if (widget.chatBox.user == 0) {
                  return Colors.blue;
                } else {
                  return Colors.grey[300];
                }
              } else {
                if (AudioPlayerManager.instance.chatId == widget.chatBox.chat_id) {
                  if (widget.chatBox.user == 0) {
                    return const Color.fromARGB(255, 28, 220, 245);
                  } else {
                    return const Color.fromARGB(255, 255, 200, 20);
                  }
                } else {
                  // return Colors.grey[300];
                  if (widget.chatBox.user == 0) {
                    return Colors.blue;
                  } else {
                    return Colors.grey[300];
                  }
                }
              }
            }
            
            return Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: getColor(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: () {
                  // 播放音频
                  playAudio(widget.chatBox);
                },
                child: Container(
                  child: Text(text, style: TextStyle(color: widget.chatBox.user == 0 ? Colors.white : Colors.black, fontSize: 16),),
                ),
              )
            );
          },
        )
      ));
  }
}
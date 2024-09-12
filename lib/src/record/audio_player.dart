import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  // 单例实例
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  // 全局共享的 AudioPlayer 实例
  AudioPlayer _audioPlayer = AudioPlayer();
  bool isDispose = false;
  // String audioPath = '';
  String chatId = '';

  // 私有构造函数
  AudioPlayerManager._internal();

  // 提供一个公开的静态方法获取实例
  static AudioPlayerManager get instance => _instance;

  // 提供对 AudioPlayer 的访问
  AudioPlayer get player => _audioPlayer;

  // 销毁方法
  void dispose() {
    _audioPlayer.dispose();
    isDispose = true;
  }

  // 重新创建播放器
  void reCreate() {
    _audioPlayer.dispose();
    _audioPlayer = AudioPlayer();
    isDispose = false;
  }
}
import 'dart:convert';

class ChatBox {
  String? type;
  String text;
  int user;
  String user_id;
  final bool? loading;
  final String time;
  final String chat_id;
  final String? quote;
  final String to_table;
  final String to_id;
  final String? receivedType;
  final String? messages_type;
  final int? message_id;
  final int? spinnerTime;
  final int? id;
  String? fileName = '';
  int? progress = 0;
  String? thumbnail = '';
  String? response = '';
  String? src = '';
  String? localFileName = '';
  int? audioDuration = 0;
  String? size = '';

  ChatBox({
    required this.text,
    required this.user,
    required this.time,
    required this.chat_id,
    required this.to_table,
    required this.to_id,
    required this.user_id,
    this.type,
    this.quote,
    this.loading,
    this.spinnerTime,
    this.id,
    this.receivedType,
    this.messages_type,
    this.message_id,
    this.progress,
    this.fileName,
    this.thumbnail,
    this.response,
    this.src,
    this.localFileName,
    this.audioDuration,
    this.size,
  });

  factory ChatBox.fromJson(Map<String, dynamic> json) {
    // bool 和 int 值从数据库出来后再次取出后，可能与原来的值类型发生了改变，所以需要转换一下
    return ChatBox(
      type: json['type'],
      text: json['text'],
      user: (json['user'] is int ? json['user'] : int.parse(json['user'])),
      time: json['time'],
      chat_id: json['chat_id'],
      quote: json['quote'],
      to_table: json['to_table'],
      to_id: json['to_id'],
      user_id: json['user_id'],
      loading: (json['loading'] is int ? (json['loading'] == 1 ? true : false) : json['loading']),
      spinnerTime: json['spinnerTime'],
      id: json['id'],
      receivedType: json['receivedType'],
      messages_type: json['messages_type'],
      message_id: json['message_id'],
      fileName: json['fileName'],
      progress: json['progress'],
      thumbnail: json['thumbnail'],
      response: json['response'],
      src: json['src'],
      localFileName: json['localFileName'],
      audioDuration: json['audioDuration'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    'user': user,
    'time': time,
    'chat_id': chat_id,
    'quote': quote,
    'to_table': to_table,
    'to_id': to_id,
    'user_id': user_id,
    'loading': loading,
    'spinnerTime': spinnerTime,
    'id': id,
    'receivedType': receivedType,
    'messages_type': messages_type,
    'message_id': message_id,
    'fileName': fileName,
    'progress': progress,
    'thumbnail': thumbnail,
    'response': response,
    'src': src,
    'localFileName': localFileName,
    'audioDuration': audioDuration,
    'size': size,
  };
}

class Token {
  final String token;
  final String refreshToken;

  Token({
    required this.token,
    required this.refreshToken
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      token: json['token'].toString(),
      refreshToken: json['refreshToken'].toString()
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
  };

  static toStr(Map<String, dynamic> json) {
    var token = json['token'].toString();
    var refreshToken = json['refreshToken'].toString();
    return '{"token": "$token", "refreshToken": "$refreshToken"}';
  }
}

class UserInfo {
  final String phoneNumber;
  final String userId;
  final String user;
  final String friends;
  final Map<String, dynamic> auth;

  UserInfo({
    required this.userId,
    required this.user,
    required this.friends,
    required this.phoneNumber,
    required this.auth
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_data']['user_id'],
      user: json['user_data']['user'],
      auth: json['auth'],
      friends: json['user_data']['friends'],
      phoneNumber: json['user_data']['phone_number'],
    );
  }

  Map<String, dynamic> toJson() => {
    'phoneNumber': phoneNumber,
    'auth': Token.toStr(auth),
    'user': user,
    'userId': userId,
    'friends': friends,
  };

  static UserInfo getfromDBJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'],
      user: json['user'],
      auth: jsonDecode(json['auth']),
      friends: json['friends'],
      phoneNumber: json['phoneNumber'],
    );
  }

  static fromJsonList(List list) {
    return list.map((item) {
      print('item ===> $item');
      return UserInfo.fromJson(item);
    }).toList();
  }

  static List<UserInfo> fromDbJsonList(List list) {
    return list.map((item) {
      return UserInfo.getfromDBJson(item);
    }).toList();
  }

}


class FriendsListStructure {
  final int? id;
  final String user;
  final String user_id;
  final String? phone_number; // ai 助手没有电话号码这个选项
  final String? db_version;
  final String? is_use_md;
  final String? created_at;
  final String? updated_at;
  final String chat_table;
  final bool? ai;
  String? avatar_url;

  FriendsListStructure(
      {required this.user_id,
      required this.phone_number,
      this.id,
      required this.user,
      this.db_version,
      this.avatar_url,
      this.is_use_md,
      this.created_at,
      this.updated_at,
      this.ai,
      required this.chat_table
      }
    );

  factory FriendsListStructure.fromJson(Map<String, dynamic> json) {
    return FriendsListStructure(
        id: json['id'],
        user: json['user'],
        user_id: json['user_id'],
        phone_number: json['phone_number'],
        db_version: json['db_version'],
        avatar_url: json['avatar_url'],
        is_use_md: json['is_use_md'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
        chat_table: json['chat_table'],
        ai: (json['ai'] == null || json['ai'] == 0) ? false : true);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'user_id': user_id,
        'phone_number': phone_number,
        'db_version': db_version,
        'avatar_url': avatar_url,
        'is_use_md': is_use_md,
        'created_at': created_at,
        'updated_at': updated_at,
        'chat_table': chat_table,
        'ai': ai
      };
  static List<FriendsListStructure> fromJsonList(List list) {
    return list.map((item) => FriendsListStructure.fromJson(item)).toList();
  }
}

// 定义数据结构是这样做的
class ChatListStructure extends FriendsListStructure {
  String? chat;
  String? time;
  int? unread;
  int? read;
  int? silent;
  ChatListStructure(
      {required super.user_id,
      required super.phone_number,
      super.id,
      required super.user,
      super.db_version,
      super.avatar_url,
      super.is_use_md,
      super.created_at,
      super.updated_at,
      required super.chat_table,
      this.chat,
      this.time,
      this.unread,
      this.read,
      this.silent});

  factory ChatListStructure.fromJson(Map<String, dynamic> json) {
    return ChatListStructure(
        id: json['id'],
        user: json['user'],
        user_id: json['user_id'],
        phone_number: json['phone_number'],
        db_version: json['db_version'],
        avatar_url: json['avatar_url'],
        is_use_md: json['is_use_md'],
        created_at: json['created_at'],
        updated_at: json['updated_at'],
        chat_table: json['chat_table'],
        chat: json['chat'],
        time: json['time'],
        unread: json['unread'],
        read: json['read'],
        silent: json['silent']);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'user_id': user_id,
        'phone_number': phone_number,
        'db_version': db_version,
        'avatar_url': avatar_url,
        'is_use_md': is_use_md,
        'created_at': created_at,
        'updated_at': updated_at,
        'chat_table': chat_table,
        'chat': chat,
        'time': time,
        'unread': unread,
        'read': read,
        'silent': silent
      };
}
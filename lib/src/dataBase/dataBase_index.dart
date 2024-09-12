import 'package:yanchat01/src/sqflite/sqflite.dart';
import 'package:yanchat01/src/util/global_type.dart';

// 插入userinfo
Future<int> insertUserInfo(UserInfo userInfo) async {
  final db = await DatabaseHelper().database;
  try {
    await db.insert('userInfo', userInfo.toJson());
    return 1;
  } catch (e) {
    print('创建UserInfo失败: $e');
    return 0;
  }
  // return await db.insert('userInfo', userInfo.toJson());
}

// 查询userinfo
Future<List<Map<String, dynamic>>> queryUserInfo(dynamic phoneNumber) async {
  final db = await DatabaseHelper().database;
  if (phoneNumber == null) {
    try {
      final List<Map<String, dynamic>> maps = await db.query('userInfo');
      return maps;
    } catch (e) {
      print('查询UserInfo失败: $e');
      return [];
    }
  }
  try {
    final List<Map<String, dynamic>> maps = await db
        .query('userInfo', where: 'phoneNumber = ?', whereArgs: [phoneNumber]);
    return maps;
  } catch (e) {
    return [];
  }
}

// 删除userinfo
Future<int> deleteUserInfo() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('DROP TABLE IF EXISTS userInfo');
    return 1;
  } catch (e) {
    print('删除UserInfo失败: $e');
    return 0;
  }
}

// 创建userinfo
Future<int> createUserInfo() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS userInfo (
        id INTEGER PRIMARY KEY,
        user TEXT, userId TEXT,
        friends TEXT,
        phoneNumber TEXT,
        auth TEXT)
      ''');
    // await db.execute('CREATE TABLE IF NOT EXISTS userInfo (id INTEGER PRIMARY KEY, user TEXT, userId TEXT, friends TEXT, phoneNumber TEXT, auth TEXT)');
    return 1;
  } catch (e) {
    print('创建UserInfo失败: $e');
    return 0;
  }
}

// 更新userinfo
Future<int> updateUserInfo(UserInfo userInfo) async {
  final db = await DatabaseHelper().database;
  try {
    await db.update('userInfo', userInfo.toJson(),
        where: 'phoneNumber = ?', whereArgs: [userInfo.phoneNumber]);
    return 1;
  } catch (e) {
    print('更新UserInfo失败: $e');
    return 0;
  }
}

// 新增好友数据
Future<int> insertFriendsList(FriendsListStructure friendsListStructure) async {
  final db = await DatabaseHelper().database;
  try {
    await db.insert('FriendsList', friendsListStructure.toJson());
    return 1;
  } catch (e) {
    print('创建FriendsList失败: $e');
    return 0;
  }
}

// 清空好友数据
Future<int> clearFriendsList() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('truncate table FriendsList');
    return 1;
  } catch (e) {
    print('清空FriendsList失败: $e');
    return 0;
  }
}

// 查询好友数据
Future<List<Map<String, dynamic>>> queryFriendsList(dynamic phoneNumber) async {
  final db = await DatabaseHelper().database;
  if (phoneNumber == null) {
    try {
      final List<Map<String, dynamic>> maps = await db.query('FriendsList');
      return maps;
    } catch (e) {
      print('查询FriendsList失败: $e');
      return [];
    }
  }
  try {
    final List<Map<String, dynamic>> maps = await db.query('FriendsList',
        where: 'phone_number = ?', whereArgs: [phoneNumber]);
    return maps;
  } catch (e) {
    return [];
  }
}

// 删除好友数据
Future<int> deleteFriendsList() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('DROP TABLE IF EXISTS FriendsList');
    return 1;
  } catch (e) {
    print('删除FriendsList失败: $e');
    return 0;
  }
}

// 创建好友数据
Future<int> createFriendsList() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS FriendsList (
          id INTEGER,
          user TEXT,
          user_id TEXT,
          avatar_url TEXT,
          is_use_md TEXT,
          db_version TEXT,
          created_at TEXT,
          updated_at TEXT,
          phone_number TEXT,
          chat_table TEXT,
          ai Boolean
        )
      ''');
    return 1;
  } catch (e) {
    print('创建FriendsList失败: $e');
    return 0;
  }
}

// 更新好友数据
Future<int> updateFriendsList(FriendsListStructure friendsListStructure) async {
  final db = await DatabaseHelper().database;
  try {
    await db.update('FriendsList', friendsListStructure.toJson(),
        where: 'phone_number = ?',
        whereArgs: [friendsListStructure.phone_number]);
    return 1;
  } catch (e) {
    print('更新FriendsList失败: $e');
    return 0;
  }
}

// 创建聊天好友数据
Future<int> createChatList() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS ChatList (
          id INTEGER,
          user TEXT,
          user_id TEXT,
          avatar_url TEXT,
          is_use_md TEXT,
          db_version TEXT,
          created_at TEXT,
          updated_at TEXT,
          phone_number TEXT,
          chat_table TEXT,
          chat TEXT,
          time TEXT,
          unread INTEGER,
          read BOOLEAN,
          silent BOOLEAN
        )
      ''');
    return 1;
  } catch (e) {
    print('创建ChatList失败: $e');
    return 0;
  }
}

// 更新聊天好友数据
Future<int> updateChatList(ChatListStructure chatListStructure) async {
  final db = await DatabaseHelper().database;
  try {
    await db.update('ChatList', chatListStructure.toJson(),
        where: 'chat_table = ?', whereArgs: [chatListStructure.chat_table]);
    return 1;
  } catch (e) {
    print('更新ChatList失败: $e');
    return 0;
  }
}

// 新增聊天好友数据
Future<int> insertChatList(ChatListStructure chatListStructure) async {
  final db = await DatabaseHelper().database;
  try {
    await db.insert('ChatList', chatListStructure.toJson());
    return 1;
  } catch (e) {
    print('创建ChatList失败: $e');
    return 0;
  }
}

// 清空聊天好友数据
Future<int> clearChatList() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('truncate table ChatList');
    return 1;
  } catch (e) {
    print('清空ChatList失败: $e');
    return 0;
  }
}

// 删除聊天好友数据
Future<int> deleteChatList() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('DROP TABLE IF EXISTS ChatList');
    return 1;
  } catch (e) {
    print('删除ChatList失败: $e');
    return 0;
  }
}

// 查询聊天好友数据
Future<List<Map<String, dynamic>>> queryChatList(dynamic phoneNumber) async {
  final db = await DatabaseHelper().database;
  if (phoneNumber == null) {
    try {
      final List<Map<String, dynamic>> maps = await db.query('ChatList');
      return maps;
    } catch (e) {
      print('查询ChatList失败: $e');
      return [];
    }
  }
  try {
    final List<Map<String, dynamic>> maps = await db
        .query('ChatList', where: 'phone_number = ?', whereArgs: [phoneNumber]);
    return maps;
  } catch (e) {
    return [];
  }
}

// 单个好友聊天框数据创建
Future<int> createChatTable(String tableName) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  try {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS $table (
          type TEXT,
          text TEXT,
          user INTEGER,
          time TEXT,
          chat_id TEXT,
          quote TEXT,
          to_table TEXT,
          to_id TEXT,
          user_id TEXT,
          loading BOOLEAN,
          spinnerTime INTEGER,
          id INTEGER,
          receivedType TEXT,
          messages_type TEXT,
          message_id INTEGER,
          created_at TEXT,
          updated_at TEXT,
          fileName TEXT,
          progress INTEGER,
          src TEXT,
          thumbnail TEXT,
          destroy BOOLEAN,
          response TEXT,
          localFileName TEXT,
          audioDuration INTEGER,
          size TEXT
        )
      ''');
    return 1;
  } catch (e) {
    print('创建ChatTable失败: $e');
    return 0;
  }
}

// 更新聊天框数据
Future<int> updateChatTable(String tableName, ChatBox chatBox) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  try {
    await db.update(table, chatBox.toJson(),
        where: 'chat_id = ?', whereArgs: [chatBox.chat_id]);
    return 1;
  } catch (e) {
    print('更新ChatTable失败: $e');
    return 0;
  }
}

// 新增聊天框数据
Future<int> insertChatTable(String tableName, ChatBox chatBox) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  try {
    await db.insert(table, chatBox.toJson());
    return 1;
  } catch (e) {
    print('插入ChatTable失败: $e');
    return 0;
  }
}

// 清空聊天框数据
Future<int> clearChatTable(String tableName) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  try {
    await db.execute('truncate table $table');
    return 1;
  } catch (e) {
    print('清空ChatTable失败: $e');
    return 0;
  }
}

// 删除聊天框数据
Future<int> deleteChatTable(String tableName, String chatId) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  try {
    await db.delete(table, where: 'chat_id = ?', whereArgs: [chatId]);
    return 1;
  } catch (e) {
    print('删除ChatTable 数据 失败: $e');
    return 0;
  }
}

// 删除聊天框表
Future<int> dropChatTable(String tableName) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  try {
    await db.execute('DROP TABLE IF EXISTS $table');
    // await db.delete(table);
    return 1;
  } catch (e) {
    print('删除ChatTable 表 失败: $e');
    return 0;
  }
}

// 查询聊天框数据
Future<List<Map<String, dynamic>>> queryChatTable(
    String tableName, String? chatId) async {
  final db = await DatabaseHelper().database;
  final table = 'chatTable_${tableName.replaceAll(r'-', '_')}';
  if (chatId == null) {
    try {
      final List<Map<String, dynamic>> maps = await db.query(table);
      return maps;
    } catch (e) {
      print('查询ChatTable失败: $e');
      return [];
    }
  }
  try {
    print('chatId***: $chatId');
    final List<Map<String, dynamic>> maps =
        await db.query(table, where: 'chat_id = ?', whereArgs: [chatId]);
    return maps;
  } catch (e) {
    return [];
  }
}

// 创建头像表
Future<int> createAvatarTable() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS avatarTable (
          id INTEGER PRIMARY KEY,
          owner_user_id TEXT,
          friend_user_id TEXT,
          avatar_url TEXT
        )
      ''');
    return 1;
  } catch (e) {
    print('创建AvatarTable失败: $e');
    return 0;
  }
}

// 查询头像数据
Future<List<Map<String, dynamic>>> queryAvatarTable(
    String ownerUserId, String friendUserId, String avatarUrl) async {
  final db = await DatabaseHelper().database;
  try {
    final List<Map<String, dynamic>> list = await db.rawQuery(
      '''
        SELECT * FROM avatarTable
        WHERE owner_user_id = ? AND friend_user_id = ? AND avatar_url LIKE ?
      ''',
      [ownerUserId, friendUserId, '%$avatarUrl%'],
    );
    return list;
  } catch (e) {
    print('查询AvatarTable失败: $e');
    return [];
  }
}

// 插入或者更新
Future<int> insertOrUpdateAvatarTable(
    String ownerUserId, String friendUserId, String avatarUrl) async {
  final db = await DatabaseHelper().database;
  try {
    await createAvatarTable();
    final updateInt = await db.update(
      'avatarTable',
      {'avatar_url': avatarUrl},
      where: 'owner_user_id = ? AND friend_user_id = ?',
      whereArgs: [ownerUserId, friendUserId],
    );
    if (updateInt == 0) {
      await db.insert(
        'avatarTable',
        {
          'owner_user_id': ownerUserId,
          'friend_user_id': friendUserId,
          'avatar_url': avatarUrl
        },
      );
    }
    return 1;
  } catch (e) {
    print('插入或者更新AvatarTable失败: $e');
    return 0;
  }
}

// 删除头像数据
Future<int> deleteAvatarTable(String ownerUserId, String friendUserId) async {
  final db = await DatabaseHelper().database;
  try {
    await db.delete(
      'avatarTable',
      where: 'owner_user_id = ? AND friend_user_id = ?',
      whereArgs: [ownerUserId, friendUserId],
    );
    return 1;
  } catch (e) {
    print('删除AvatarTable失败: $e');
    return 0;
  }
}

// 删除头像表
Future<int> dropAvatarTable() async {
  final db = await DatabaseHelper().database;
  try {
    await db.execute('DROP TABLE IF EXISTS avatarTable');
    return 1;
  } catch (e) {
    print('删除AvatarTable失败: $e');
    return 0;
  }
}

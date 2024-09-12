import "package:flutter/material.dart";
import '../../src/chatList/chat_list_index.dart';
import '../setting/setting_index.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/login/login_index.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/ws/ws_index.dart';
import 'package:yanchat01/src/friends/friends_index.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  String userId = '';
  void _onItemTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void _initLoginMethod(BuildContext context) async {
    try {
      var data = await queryUserInfo(null);
      if (data.isNotEmpty) {
        // 连接后台，websocket 继续通信
        final boxDataNotifier =
            Provider.of<BoxDataNotifier>(context, listen: false);
        var ws = Ws(boxDataNotifier: boxDataNotifier);
        // 初始化页面id记录
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('activeId', '');
        ws.connect();

        if (boxDataNotifier.userInfo == null) {
          boxDataNotifier.setUserInfo(UserInfo.fromDbJsonList(data)[0]);
        }
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const Scaffold(
            body: LoginPage(),
          );
        }));
      }
    } catch (e) {
      print('err =>: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLoginMethod(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BoxDataNotifier>(
        builder: (context, BoxDataNotifier boxChatNotifier, child) {
      return Scaffold(
          appBar: AppBar(
            title: currentIndex != 2 ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('燕言'),
                // const Spacer(),
                Text("（${boxChatNotifier.connecteStatus}）")
              ],
            ) : const SizedBox(),
            backgroundColor: const Color.fromARGB(255, 236, 236, 236),

            // titleTextStyle: const TextStyle(
            //     color: Color.fromARGB(255, 41, 41, 41), fontSize: 18),
            // elevation: 1.0,
            // shadowColor: Colors.grey[200],
          ),
          body: _buildPage(currentIndex, context),
          backgroundColor:  currentIndex == 2 ? const Color.fromARGB(255, 236, 236, 236) : Colors.white,
          // 设置底部导航 material 用于设置elevation，加阴影用
          bottomNavigationBar: Material(
            elevation: 10.0,
            child: Theme(
              // 设置底部导航的主题（去掉点击波浪效果）
              data: ThemeData(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  brightness: Brightness.light),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: _onItemTapped,
                selectedItemColor: Colors.blueAccent.withOpacity(0.5),
                unselectedFontSize: 12,
                selectedFontSize: 12,
                backgroundColor: const Color.fromARGB(255, 236, 236, 236),
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Stack(
                        fit: StackFit.passthrough,
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat_bubble),
                          if (boxChatNotifier.totalUnread > 0)
                            Positioned(
                                right: -10,
                                top: -16,
                                child: Container(
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    boxChatNotifier.totalUnread.toString(),
                                    style: const TextStyle(
                                        fontSize: 14.0, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ))
                        ],
                      ),
                    ),
                    label: '聊天',
                  ),
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Icon(Icons.people),
                    ),
                    label: '好友',
                  ),
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Icon(Icons.settings),
                    ),
                    label: '设置',
                  ),
                ],
              ),
            ),
          ));
    });
  }

  Widget _buildPage(int currentIndex, BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: IndexedStack(
        index: currentIndex,
        children: const <Widget>[
          ChatList(),
          FriendsList(),
          Setting(),
        ],
      ),
    );
  }
}

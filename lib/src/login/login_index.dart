import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:yanchat01/src/home/home_index.dart';
import 'package:provider/provider.dart';
import 'package:yanchat01/src/index.dart';
import 'dart:convert';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/request.dart';
import 'package:yanchat01/src/util/share.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  int loginSign = 0;

  // 检查手机号码是否合法
  bool checkPhone(String phone) {
    RegExp regExp = RegExp(r'^1[3456789]\d{9}$');
    return regExp.hasMatch(phone);
  }

  // 登陆成功执行
  void _loginSuccess(Response response, String phone,BuildContext context) async {
    var user = await queryUserInfo(phone);
    var userinfo = UserInfo.fromJson(response.data);
    Share.instance.setString('token', userinfo.auth['token']);
    Share.instance.setString('refreshToken', userinfo.auth['refreshToken']);
    if (user.isEmpty) {
      await deleteUserInfo();
      await deleteFriendsList();
      await deleteChatList();
    }
    await createUserInfo();
    await createFriendsList();
    await createChatList();
    if (user.isEmpty) {
      await insertUserInfo(userinfo);
    }
    Share.instance.setString('userId', userinfo.userId);

    var friendsList = await queryFriendsList(null);
    // 每次登陆都清空好友列表
    if (friendsList.isNotEmpty) {
      clearFriendsList();
    }
    final friendsStr = userinfo.friends;
    if (friendsStr.isNotEmpty) {
      final List<dynamic> friList = jsonDecode(friendsStr);
      for (var e in friList) {
        await insertFriendsList(FriendsListStructure.fromJson(e));
      }
    }

    var boxData = Provider.of<BoxDataNotifier>(context, listen: false);
    boxData.setLogIn(userinfo);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
      return const Home();
    }));
  }

  void userRegister(String phone, String password ,BuildContext context) async {
    // final baseUrl = prefs.getString('baseUrl') ?? '';
    final baseUrl = await Share.instance.getString('baseUrl') ?? '';

    Response? response;
    try {
      response = await Request.instance.dio.post('$baseUrl/register', data: {
        'phone_number': phone,
        'password': password
      });
      if (response.data['user_data'] == 'err') {
        setState(() {
          _errorMessage = '注册失败';
        });
        return null;
      } else if (response.data['user_data'] == 'exist') {
        setState(() {
          _errorMessage = '手机号已被注册';
        });
        return null;
      } else {
        setState(() {
          _errorMessage = '';
        });
      }
    } catch (e) {
      // print(e);
      setState(() {
        _errorMessage = '注册失败';
      });
      return null;
    }
    _loginSuccess(response, phone, context);
  }

  void _loginOnPress(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      String phone = _phoneController.text;
      String password = _passwordController.text;
      String baseUrl = 'http://10.147.20.119:9999';
      String baseWsUrl = 'ws://10.147.20.119:9999';

      final regPhone = checkPhone(phone);

      if (!regPhone) {
        setState(() {
          _errorMessage = '请输入正确的手机号码';
        });
        return;
      }

      Share.instance.setString('baseUrl', baseUrl);
      Share.instance.setString('baseWsUrl', baseWsUrl);
      Response response = await Request.instance.dio.post(
        '$baseUrl/login',
        data: {
          'phone_number': phone,
          'password': password,
        },
      );

      if (response.data['user_data'] == null) {
        return null;
      }

      // print("user 数据 =》 ${response.data}");
      if (response.data['auth'] == null) {
        print("登陆失败，可能重复登陆或者密码错误 =》 ${response.data}");
        if (response.data['user_data'] == 'repeat') {
          setState(() {
            _errorMessage = '重复登陆';
          });
        } else if (response.data['user_data'] == 'pw_err') {
          setState(() {
            _errorMessage = '密码错误';
          });
        } else {
          setState(() {
            _errorMessage = '';
          });
          // 到了这步，就是没有注册过
          final isRegister = await registerPop();
          if (isRegister == true) {
            // _loginOnPress(context);
            print("注册成功");
            userRegister(phone, password, context);
          } else {
            print("取消注册");
          }
        }
        return null;
      }
      setState(() {
        _errorMessage = '';
      });

      // 登陆成功
      _loginSuccess(response, phone, context);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool?> registerPop() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          icon: const Icon(
            Icons.info,
            size: 40,
            color: Colors.blueAccent,
          ),
          content: const Align(
            alignment: Alignment.center,
            heightFactor: 1.0,
            child: Text(
              "该电话尚未注册，是否注册?",
              style: TextStyle(fontSize: 16),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(
            bottom: 20.0,
            top: 0.0,
            left: 0.0,
            right: 0.0,
          ),
          actions: <Widget>[
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.blueAccent,
              ),
              child: TextButton(
                child: const Text(
                  "注册",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  //关闭对话框并返回true
                  Navigator.of(context).pop(true);
                },
              ),
            ),
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey[300],
              ),
              child: TextButton(
                child: const Text(
                  "取消",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  //关闭对话框并返回true
                  Navigator.of(context).pop(false);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 236, 236, 236),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '手机号',
                  floatingLabelStyle: TextStyle(color: Colors.blue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 未激活时的下边框颜色
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue, width: 2.0), // 激活时的下边框颜色
                  ),
                ),
                style: const TextStyle(fontSize: 20.0),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入你的手机号';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  floatingLabelStyle: TextStyle(color: Colors.blue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey), // 未激活时的下边框颜色
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue, width: 2.0), // 激活时的下边框颜色
                  ),
                ),
                style: const TextStyle(fontSize: 20.0),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入你的密码';
                  }
                  return null;
                },
              ),
              // 提示登录错误信息
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 64.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _loginOnPress(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 32.0),
                    textStyle: const TextStyle(
                      fontSize: 20.0, // 设置字体大小
                      fontWeight: FontWeight.bold, // 设置字体粗细
                    ),
                  ),
                  child: const Text('登录'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

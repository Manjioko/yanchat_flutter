import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:yanchat01/src/avatar/avatar_index.dart';
import 'package:yanchat01/src/index.dart';
import 'package:yanchat01/src/login/login_index.dart';
import 'package:yanchat01/src/dataBase/dataBase_index.dart';
import 'package:dio/dio.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/image_handler.dart';
import 'package:yanchat01/src/util/request.dart';
import 'dart:io';

import 'package:yanchat01/src/util/share.dart';
// import 'package:yanchat01/src/util/image_handler.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  Key key = UniqueKey();
  ImageProvider? avatarImage;

  @override
  void initState() {
    super.initState();
    settingAvatar();
  }

  void settingAvatar() async {
    final userId = await Share.instance.getString('userId');
    if (userId != null) {
      setAvatar(userId, context, callback: () {
        setState(() {
          key = UniqueKey();
        });
      });
    }
  }

  void _press(BuildContext context) async {
    await deleteUserInfo();
    await deleteFriendsList();
    await deleteChatList();
    await dropAvatarTable();
    var boxData = Provider.of<BoxDataNotifier>(context, listen: false);
    boxData.getWebsocket()?.close();
    // print('result: $result');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return const Scaffold(
        body: LoginPage(),
      );
    }));
  }

  _handleUploadAvatar(String? userId, BuildContext context) async {
    if (userId == null) {
      return;
    }
    final binaryData = await getMediaFromGallery();
    // 用户取消
    if (binaryData == null) {
      return;
    }

    final avatarBinaryData = await createAvatar(binaryData);
    if (avatarBinaryData == null) {
      print('头像转换失败');
      return;
    }

    // 开始上传
    final baseUrl = await Share.instance.getString('baseUrl') ?? '';
    if (baseUrl.isEmpty) {
      print('未设置baseUrl');
      return;
    }
    Request.instance.dio
        .post(
      '$baseUrl/uploadAvatar',
      data: FormData.fromMap({
        'avatar': MultipartFile.fromBytes(avatarBinaryData,
            filename: 'avatar_$userId.jpg'),
        'user_id': userId
      }),
    )
        .then((res) async {
      if (res.statusCode == 200) {
        await updateAvatar(userId, context);
        setState(() {
          key = UniqueKey();
        });
        print('上传成功, userId ：$userId');
      }
    }).catchError((e) {
      print('上传失败：$e');
    });

    try {
      File(binaryData.path).delete();
    } catch (e) {
      print('删除临时文件失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BoxDataNotifier, UserInfo?>(
        selector: (context, boxData) => boxData.userInfo,
        builder: (context, userinfo, child) {
          final userId = userinfo?.userId;
          // 算屏幕宽度
          final screenWidth = MediaQuery.of(context).size.width;

          return Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Column(
                  children: [
                    // 头像
                    Avatar(
                        key: key,
                        width: 100,
                        height: 100,
                        userId: userId ?? ''),
                    if (userId != null)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(userinfo?.user ?? '',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 0.0,
                          // left: 10.0,
                          // right: 10.0,
                          bottom: 20.0),
                      child: Text('86+ ${userinfo?.phoneNumber ?? ''}',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                    )
                  ],
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _handleUploadAvatar(userId, context);
                      },
                      child: Container(
                        width: screenWidth - 32,
                        height: 48,
                        // padding: const EdgeInsets.only(left: 50),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                            ),
                            border: Border(
                                bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1.0,
                            ))),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 16.0, right: 16.0),
                              child: Icon(
                                Icons.switch_account_sharp,
                                size: 24,
                                color: Color.fromARGB(255, 102, 102, 102),
                              ),
                            ),
                            Text("更换头像",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w300)),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.only(right: 14),
                              child: Icon(
                                Icons.chevron_right,
                                size: 24,
                                color: Color.fromARGB(255, 102, 102, 102),
                              ),
                            )
                            // 设置箭头撑满其余空间
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: screenWidth - 32,
                      height: 48,
                      // padding: const EdgeInsets.only(left: 50),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16.0, right: 16.0),
                            child: Icon(
                              Icons.person,
                              size: 24,
                              color: Color.fromARGB(255, 102, 102, 102),
                            ),
                          ),
                          Text("更换用户名",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w300)),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.chevron_right,
                              size: 24,
                              color: Color.fromARGB(255, 102, 102, 102),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: screenWidth - 32,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => _press(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Icon(
                            Icons.logout_outlined,
                            size: 24,
                            color: Color.fromARGB(255, 102, 102, 102),
                          ),
                        ),
                        Text("退出登录",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.red)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }
}

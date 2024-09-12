import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/index.dart';

class Avatar extends StatefulWidget {
  final double width;
  final double height;
  final String userId;
  const Avatar(
      {super.key,
      required this.width,
      required this.height,
      required this.userId});

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  @override
  Widget build(BuildContext context) {
    return Selector<BoxDataNotifier, Map?>(
        selector: (context, boxNotifier) => boxNotifier.avatarMap,
        builder: (context, avatarMap, child) {
          final avatarUrl = avatarMap?[widget.userId];
          String url = 'images/default_avatar.png';
          if (avatarUrl != null) {
            if (avatarUrl.isNotEmpty) {
              // print('更新到了吗：$avatarUrl');
              url = avatarUrl;
            }
          }
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(url),
                fit: BoxFit.cover,
              ),
            ),
          );
        });
  }
}

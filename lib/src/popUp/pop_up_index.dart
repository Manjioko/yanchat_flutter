import 'package:flutter/material.dart';
import 'package:yanchat01/src/util/global_type.dart';
import 'package:yanchat01/src/util/withdraw_handler.dart';

class PopUp extends StatefulWidget {
  final Widget child;
  final ChatBox? chatBox;
  const PopUp({super.key, required this.child, required this.chatBox});

  @override
  State<PopUp> createState() => _PopUpState();
}

class _PopUpState extends State<PopUp> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Navigator.of(context).push(
          CustomPopupRoute(
            child: _buildPopupMenu(context),
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double yPosition = position.dy;
    // double xPosition = position.dx;
    
    // 如果 position 的 y 值超过了屏幕 3/4,就需要将top设置成 position.dy + size.height + 80
    if (position.dy < screenHeight / 4) {
      yPosition = position.dy + size.height + 10;
    } else {
      yPosition = position.dy - 60;
    }

    return Stack(
      children: [
        Container(
          width: size.width,
          height: size.height,
          color: Colors.transparent,
        ),
        Positioned(
          right: widget.chatBox?.user == 0 ? 30 : null,
          left: widget.chatBox?.user == 1 ? 30 : null,
          top: yPosition,
          child: Material(
            color: Colors.transparent,
            child: Container(
              // color: Colors.black,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close popup
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text("复制",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Close popup
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text("删除",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  if (widget.chatBox?.user == 0)
                  GestureDetector(
                    onTap: () {
                      withdrawHandler(widget.chatBox, context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text("撤回",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

class CustomPopupRoute extends PopupRoute<void> {
  CustomPopupRoute({
    required this.child,
  });

  final Widget child;

  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 使透明区域也能接收到触摸事件
      onPanDown: (details) {
        // 在手指按下时记录位置，但不立即关闭
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Navigator.of(context).pop();
        }
      },
      onPanUpdate: (details) {
        // 在用户移动手指时关闭 PopupRoute，并允许屏幕继续滚动
        // if (ModalRoute.of(context)?.isCurrent ?? false) {
        //   Navigator.of(context).pop();
        // }
      },
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
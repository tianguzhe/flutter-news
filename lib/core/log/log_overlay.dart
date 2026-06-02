import 'package:flutter/material.dart';

/// 全局日志悬浮球。
///
/// 通过 [MaterialApp.builder] 包裹在所有页面之上，因此在任意路由都可见、可点击。
/// 悬浮球可拖动，点击触发 [onTap]（通常用于跳转到日志页）。
class LogOverlay extends StatefulWidget {
  const LogOverlay({super.key, required this.child, required this.onTap});

  /// 被包裹的页面内容（即 MaterialApp.builder 的 child）。
  final Widget child;

  /// 点击悬浮球的回调；其返回的 Future 完成（通常是目标页被 pop）前，
  /// 重复点击会被忽略，从而避免命令式 push 叠加多层页面。
  final Future<void> Function() onTap;

  @override
  State<LogOverlay> createState() => _LogOverlayState();
}

class _LogOverlayState extends State<LogOverlay> {
  static const double _size = 48;

  /// 悬浮球左上角坐标；null 表示尚未拖动，使用默认右下角位置。
  Offset? _offset;

  /// 目标页是否已打开；打开期间忽略再次点击，避免命令式 push 叠加多层。
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final inset = MediaQuery.paddingOf(context);

    // 默认停靠在右下角，避开底部安全区与常见的 FAB 区域。
    final offset =
        _offset ??
        Offset(
          screen.width - _size - 16,
          screen.height - _size - inset.bottom - 96,
        );

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: GestureDetector(
            onTap: () async {
              if (_opening) return;
              _opening = true;
              try {
                await widget.onTap();
              } finally {
                _opening = false;
              }
            },
            onPanUpdate: (details) {
              final next = offset + details.delta;
              // 限制在屏幕可视范围内，避免被拖出边界后无法点回。
              setState(() {
                _offset = Offset(
                  next.dx.clamp(0.0, screen.width - _size),
                  next.dy.clamp(
                    inset.top,
                    screen.height - _size - inset.bottom,
                  ),
                );
              });
            },
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              elevation: 4,
              child: const SizedBox(
                width: _size,
                height: _size,
                child: Icon(
                  Icons.bug_report_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

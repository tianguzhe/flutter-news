import 'package:talker_flutter/talker_flutter.dart';

/// 全局共享的 Talker 实例。
///
/// dio（TalkerDioLogger）、riverpod（TalkerRiverpodObserver）等 talker 组件
/// 都传入这一个实例，使网络日志、状态日志统一汇入同一处，便于集中查看与上报。
final talker = TalkerFlutter.init();

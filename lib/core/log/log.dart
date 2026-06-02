import 'package:talker_logger/talker_logger.dart';

/// 全局日志入口：用静态方法包装单例 [TalkerLogger]，
/// 调用处统一写成 Log.d(...) / Log.i(...) 等，避免到处 new logger。
class YLog {
  const YLog._();

  static final TalkerLogger _logger = TalkerLogger(
    settings: TalkerLoggerSettings(
      colors: {
        // #FDFFFB
        LogLevel.verbose: AnsiPen()..rgb(r: 0.992, g: 1.0, b: 0.984),
        // #54CEE3
        LogLevel.debug: AnsiPen()..rgb(r: 0.329, g: 0.808, b: 0.890),
        // #55E350
        LogLevel.info: AnsiPen()..rgb(r: 0.333, g: 0.890, b: 0.314),
        // #F8DA3F
        LogLevel.warning: AnsiPen()..rgb(r: 0.973, g: 0.855, b: 0.247),
        // #FF5370
        LogLevel.error: AnsiPen()..rgb(r: 1.0, g: 0.325, b: 0.439),
        // #FF9492 (ASSERT)
        LogLevel.critical: AnsiPen()..rgb(r: 1.0, g: 0.580, b: 0.573),
      },
    ),
  );

  /// verbose
  static void v(String msg) => _logger.verbose(msg);

  /// debug
  static void d(String msg) => _logger.debug(msg);

  /// info
  static void i(String msg) => _logger.info(msg);

  /// warning
  static void w(String msg) => _logger.warning(msg);

  /// error
  static void e(String msg) => _logger.error(msg);

  /// assert
  static void wtf(String msg) => _logger.critical(msg);
}
